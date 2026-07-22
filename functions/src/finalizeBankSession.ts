import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  REGION,
  ASPSP_NAME,
  aspspSlug,
  bankConnectionDoc,
  ENABLEBANKING_PEM,
  ENABLEBANKING_APP_ID,
} from "./config.js";
import {
  buildEnableBankingJwt,
  enableBankingFetch,
  requireUid,
} from "./enableBanking.js";

interface SessionResponse {
  session_id: string;
  accounts?: unknown[];
  aspsp?: { name?: string; country?: string };
  access?: { valid_until?: string };
}

/**
 * Fase 1 — tanca l'autorització AIS bescanviant el `code` de la SCA per una sessió.
 *
 * Passos:
 *  1. Valida que el `state` rebut coincideix amb el desat a startBankAuth (anti-CSRF)
 *     ABANS de cridar Enable Banking, i el descarta (un sol ús).
 *  2. POST /sessions amb el `code` → session_id + comptes autoritzats.
 *  3. Desa session_id + valid_until a users/{uid}/bank_connections/caixabank.
 */
export const finalizeBankSession = onCall(
  {
    region: REGION,
    secrets: [ENABLEBANKING_PEM, ENABLEBANKING_APP_ID],
  },
  async (request) => {
    const uid = requireUid(request);

    const code = (request.data?.code ?? "") as string;
    const state = (request.data?.state ?? "") as string;
    if (!code || !state) {
      throw new HttpsError(
        "invalid-argument",
        "Falten paràmetres d'autorització (code/state)."
      );
    }

    const slug = aspspSlug(ASPSP_NAME.value());
    const db = getFirestore();
    const docRef = db.doc(bankConnectionDoc(uid, slug));
    const snap = await docRef.get();
    const pendingState = snap.get("pendingState") as string | undefined;

    // 1. Validació anti-CSRF, d'un sol ús, ABANS de cridar Enable Banking.
    if (!pendingState || pendingState !== state) {
      logger.warn("State d'autorització bancària no vàlid o ja consumit", {
        uid,
      });
      // Consumim qualsevol pendingState per evitar reutilització/replay.
      await docRef.set(
        { pendingState: FieldValue.delete() },
        { merge: true }
      );
      throw new HttpsError(
        "permission-denied",
        "La sessió d'autorització no és vàlida. Torna a connectar el banc."
      );
    }

    const jwt = await buildEnableBankingJwt(
      ENABLEBANKING_APP_ID.value(),
      ENABLEBANKING_PEM.value()
    );

    // 2. Bescanviar el code per una sessió. El `code` es tracta com a credencial:
    //    mai va a logs.
    const session = await enableBankingFetch<SessionResponse>("/sessions", {
      method: "POST",
      jwt,
      body: { code },
    });

    if (!session.session_id) {
      throw new HttpsError(
        "internal",
        "Enable Banking no ha retornat cap sessió."
      );
    }

    const validUntil =
      session.access?.valid_until ??
      (snap.get("pendingValidUntil") as string | undefined) ??
      null;

    // 3. Persistir la sessió i descartar el state (un sol ús).
    await docRef.set(
      {
        sessionId: session.session_id,
        accounts: session.accounts ?? [],
        validUntil,
        status: "connected",
        connectedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        pendingState: FieldValue.delete(),
        pendingValidUntil: FieldValue.delete(),
      },
      { merge: true }
    );

    logger.info("Sessió bancària establerta", {
      uid,
      accountCount: (session.accounts ?? []).length,
      validUntil,
    });

    // No retornem session_id ni code al client.
    return {
      status: "connected",
      accountCount: (session.accounts ?? []).length,
      validUntil,
    };
  }
);
