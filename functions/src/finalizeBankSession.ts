import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  REGION,
  bankConnectionsCollection,
  BANK_FUNCTION_SECRETS,
} from "./config.js";
import {
  buildEnableBankingJwt,
  enableBankingFetch,
  requireUid,
} from "./enableBanking.js";
import {
  APP_CHANGED,
  credentialsFor,
  requireBankAccess,
  shortAppId,
} from "./bankApp.js";

interface SessionResponse {
  session_id: string;
  accounts?: unknown[];
  aspsp?: { name?: string; country?: string };
  access?: { valid_until?: string };
}

/**
 * Tanca l'autorització AIS bescanviant el `code` de la SCA per una sessió.
 *
 *  1. Valida que el `state` rebut coincideix amb el desat a startBankAuth
 *     (anti-CSRF) ABANS de cridar Enable Banking, i el descarta (un sol ús).
 *  2. Exigeix que l'aplicació del grup sigui la mateixa amb què es va iniciar.
 *  3. POST /sessions amb el `code` → session_id + comptes autoritzats.
 *  4. Desa la sessió i l'appId amb què s'ha creat.
 */
export const finalizeBankSession = onCall(
  {
    region: REGION,
    secrets: BANK_FUNCTION_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    // Abans de qualsevol crida a Enable Banking.
    const access = await requireBankAccess(db, uid);

    const code = (request.data?.code ?? "") as string;
    const state = (request.data?.state ?? "") as string;
    if (!code || !state) {
      throw new HttpsError(
        "invalid-argument",
        "Falten paràmetres d'autorització (code/state)."
      );
    }

    const pending = await db
      .collection(bankConnectionsCollection(uid))
      .where("pendingState", "==", state)
      .limit(2)
      .get();

    // 1. Validació anti-CSRF, d'un sol ús, ABANS de cridar Enable Banking.
    if (pending.size !== 1) {
      logger.warn("State d'autorització bancària no vàlid o ja consumit", {
        uid,
        matches: pending.size,
      });
      throw new HttpsError(
        "permission-denied",
        "La sessió d'autorització no és vàlida. Torna a connectar el banc."
      );
    }
    const snap = pending.docs[0];
    const docRef = snap.ref;
    const connectionId = snap.id;
    if (snap.get("groupId") !== access.groupId) {
      throw new HttpsError(
        "permission-denied",
        "Aquesta connexió bancària no pertany al grup actiu."
      );
    }

    // 2. L'aplicació no pot haver canviat enmig de la SCA.
    const creds = credentialsFor(access);
    const pendingAppId = snap.get("pendingAppId") as string | undefined;
    if (pendingAppId && pendingAppId !== creds.appId) {
      await docRef.set(
        {
          pendingState: FieldValue.delete(),
          pendingValidUntil: FieldValue.delete(),
          pendingAppId: FieldValue.delete(),
        },
        { merge: true }
      );
      throw new HttpsError(
        "failed-precondition",
        "L'aplicació bancària del grup ha canviat mentre connectaves. Torna-ho a provar.",
        { needsReauth: true, reason: APP_CHANGED, connectionId }
      );
    }

    // 3. Bescanviar el code per una sessió. El `code` es tracta com a
    //    credencial: mai va a logs.
    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);
    const session = await enableBankingFetch<SessionResponse>("/sessions", {
      method: "POST",
      jwt,
      baseUrl: creds.baseUrl,
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

    // 4. Persistir la sessió i descartar el state (un sol ús).
    const accounts = session.accounts ?? [];
    const aspspName = (snap.get("aspspName") as string | undefined) ?? "Banc";
    const inferredLabel = accounts
      .map((account) =>
        typeof account === "object" && account != null && "name" in account
          ? String((account as { name?: unknown }).name ?? "").trim()
          : ""
      )
      .find(Boolean);

    await docRef.set(
      {
        connectionId,
        sessionId: session.session_id,
        accounts,
        connectionLabel:
          (snap.get("connectionLabel") as string | undefined) ??
          inferredLabel ??
          aspspName,
        validUntil,
        appId: creds.appId,
        env: creds.env,
        status: "connected",
        connectedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        pendingState: FieldValue.delete(),
        pendingValidUntil: FieldValue.delete(),
        pendingAppId: FieldValue.delete(),
        reconnectReason: FieldValue.delete(),
        inactiveReason: FieldValue.delete(),
      },
      { merge: true }
    );

    logger.info("Sessió bancària establerta", {
      uid,
      connectionId,
      app: shortAppId(creds.appId),
      accountCount: accounts.length,
      validUntil,
    });

    // No retornem session_id ni code al client. Amb 0 comptes, l'app explica
    // que cal que l'owner enllaci el compte al panell (mode restringit).
    return {
      status: "connected",
      connectionId,
      accountCount: accounts.length,
      noLinkedAccounts: accounts.length === 0,
      aspspName,
      validUntil,
    };
  }
);
