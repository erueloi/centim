import { randomUUID } from "node:crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  REGION,
  REDIRECT_URL,
  ASPSP_COUNTRY,
  ASPSP_NAME,
  aspspSlug,
  PSU_TYPE,
  REQUESTED_CONSENT_DAYS,
  bankConnectionDoc,
  ENABLEBANKING_PEM,
  ENABLEBANKING_APP_ID,
} from "./config.js";
import {
  buildEnableBankingJwt,
  enableBankingFetch,
  requireUid,
} from "./enableBanking.js";

interface Aspsp {
  name: string;
  country: string;
  /** Validesa màxima del consentiment en segons. */
  maximum_consent_validity?: number;
  auth_methods?: unknown[];
  psu_types?: string[];
}

interface AspspsResponse {
  aspsps: Aspsp[];
}

interface AuthResponse {
  /** URL a què l'app ha de redirigir l'usuari per fer la SCA. */
  url: string;
}

/**
 * Fase 1 — inicia l'autorització AIS amb CaixaBank via Enable Banking.
 *
 * Passos:
 *  1. Signa un JWT curt (RS256).
 *  2. GET /aspsps?country=ES → localitza CaixaBank i llegeix la seva validesa màxima.
 *  3. Genera un `state` anti-CSRF d'un sol ús i el desa a Firestore.
 *  4. POST /auth amb valid_until dinàmic → retorna la redirect_url de SCA.
 */
export const startBankAuth = onCall(
  {
    region: REGION,
    secrets: [ENABLEBANKING_PEM, ENABLEBANKING_APP_ID],
  },
  async (request) => {
    const uid = requireUid(request);

    const targetName = ASPSP_NAME.value();
    const targetCountry = ASPSP_COUNTRY.value();

    const jwt = await buildEnableBankingJwt(
      ENABLEBANKING_APP_ID.value(),
      ENABLEBANKING_PEM.value()
    );

    // 2. Localitzar el banc objectiu entre les ASPSP del país.
    const aspspsResp = await enableBankingFetch<AspspsResponse>("/aspsps", {
      method: "GET",
      jwt,
      query: { country: targetCountry },
    });

    const list = aspspsResp.aspsps ?? [];
    const nameLc = targetName.toLowerCase();
    const caixa =
      list.find(
        (a) => a.country === targetCountry && a.name.toLowerCase() === nameLc
      ) ??
      list.find(
        (a) =>
          a.country === targetCountry && a.name.toLowerCase().includes(nameLc)
      );

    if (!caixa) {
      logger.error("Banc objectiu no trobat a /aspsps", {
        country: targetCountry,
        target: targetName,
        count: list.length,
      });
      throw new HttpsError(
        "not-found",
        `${targetName} no està disponible ara mateix a Enable Banking.`
      );
    }

    // Slug derivat del paràmetre (no del nom retornat) perquè finalizeBankSession
    // pugui recalcular el mateix doc sense tornar a cridar /aspsps.
    const slug = aspspSlug(targetName);

    // 3. valid_until dinàmic, capat a la validesa màxima real de CaixaBank.
    const requestedSeconds = REQUESTED_CONSENT_DAYS * 24 * 60 * 60;
    const maxSeconds = caixa.maximum_consent_validity ?? requestedSeconds;
    const validSeconds = Math.min(requestedSeconds, maxSeconds);
    const validUntil = new Date(Date.now() + validSeconds * 1000).toISOString();

    // 4. State anti-CSRF d'un sol ús, desat abans d'iniciar la SCA.
    const state = randomUUID();
    const db = getFirestore();
    await db.doc(bankConnectionDoc(uid, slug)).set(
      {
        aspspName: caixa.name,
        aspspCountry: caixa.country,
        pendingState: state,
        pendingValidUntil: validUntil,
        status: "authorizing",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // 5. Iniciar autorització.
    const auth = await enableBankingFetch<AuthResponse>("/auth", {
      method: "POST",
      jwt,
      body: {
        access: { valid_until: validUntil },
        aspsp: { name: caixa.name, country: caixa.country },
        state,
        redirect_url: REDIRECT_URL,
        psu_type: PSU_TYPE,
      },
    });

    if (!auth.url) {
      throw new HttpsError(
        "internal",
        "Enable Banking no ha retornat cap URL d'autorització."
      );
    }

    logger.info("Autorització bancària iniciada", {
      uid,
      aspsp: caixa.name,
      validUntil,
    });

    // No retornem el `state` al client: viu a Firestore i tornarà via redirect.
    return {
      authUrl: auth.url,
      aspspName: caixa.name,
      validUntil,
      authMethods: caixa.auth_methods ?? [],
    };
  }
);
