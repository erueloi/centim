import { randomUUID } from "node:crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  REGION,
  resolveRedirectUrl,
  ASPSP_COUNTRY,
  ASPSP_NAME,
  aspspSlug,
  PSU_TYPE,
  REQUESTED_CONSENT_DAYS,
  bankConnectionDoc,
  ALL_EB_SECRETS,
  resolveEbCredentials,
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
    secrets: ALL_EB_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);

    const targetName = ASPSP_NAME.value();
    const targetCountry = ASPSP_COUNTRY.value();
    // Redirect dinàmic (web desplegada o localhost en dev), validat.
    let redirectUrl: string;
    try {
      redirectUrl = resolveRedirectUrl(
        request.data?.redirectUrl as string | undefined
      );
    } catch {
      throw new HttpsError("invalid-argument", "redirect_url no permès.");
    }
    const creds = resolveEbCredentials();

    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);

    // 2. Localitzar el banc objectiu entre les ASPSP del país.
    const aspspsResp = await enableBankingFetch<AspspsResponse>("/aspsps", {
      method: "GET",
      jwt,
      baseUrl: creds.baseUrl,
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
      baseUrl: creds.baseUrl,
      body: {
        access: { valid_until: validUntil },
        aspsp: { name: caixa.name, country: caixa.country },
        state,
        redirect_url: redirectUrl,
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
      env: creds.env,
      aspsp: caixa.name,
      validUntil,
    });

    // No retornem el `state` al client: viu a Firestore i tornarà via redirect.
    return {
      env: creds.env,
      authUrl: auth.url,
      aspspName: caixa.name,
      validUntil,
      authMethods: caixa.auth_methods ?? [],
    };
  }
);
