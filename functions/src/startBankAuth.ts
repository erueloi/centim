import { randomUUID } from "node:crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import {
  DocumentSnapshot,
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

import {
  REGION,
  resolveRedirectUrl,
  aspspSlug,
  PSU_TYPE,
  REQUESTED_CONSENT_DAYS,
  bankConnectionDoc,
  BANK_FUNCTION_SECRETS,
} from "./config.js";
import {
  buildEnableBankingJwt,
  enableBankingFetch,
  requireUid,
} from "./enableBanking.js";
import { assertValidConnectionId } from "./bankConnections.js";
import {
  credentialsFor,
  findAspsp,
  normalizeCountry,
  requireBankAccess,
  shortAppId,
} from "./bankApp.js";

interface AuthResponse {
  /** URL a què l'app ha de redirigir l'usuari per fer la SCA. */
  url: string;
}

/** Marge sobre la validesa màxima de l'ASPSP (rellotge i latència). */
const CONSENT_MARGIN_SECONDS = 60 * 60;

/** Segons de consentiment a demanar: el màxim de l'ASPSP menys el marge. */
export function consentSecondsFor(maximumSeconds: number): number {
  return maximumSeconds > 2 * CONSENT_MARGIN_SECONDS
    ? maximumSeconds - CONSENT_MARGIN_SECONDS
    : Math.floor(maximumSeconds * 0.9);
}

/** Banc de les connexions anteriors al multi banc (no tenien aspspName). */
const LEGACY_ASPSP = { name: "CaixaBank", country: "ES" };

/**
 * Inicia l'autorització AIS amb l'aplicació d'Enable Banking DEL GRUP.
 *
 *  - Connexió nova: `aspspName` + `aspspCountry` (el banc que tria l'usuari).
 *  - Renovació/reconnexió: `connectionId`; el banc és el desat a la connexió.
 *    Reconnectar és també com una connexió creada amb una aplicació anterior
 *    passa a l'aplicació actual del grup.
 *
 * La validesa demanada és la màxima que admet l'ASPSP.
 */
export const startBankAuth = onCall(
  {
    region: REGION,
    secrets: BANK_FUNCTION_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    // Abans de qualsevol crida a Enable Banking.
    const access = await requireBankAccess(db, uid);
    const groupId = access.groupId;

    // Redirect dinàmic (web desplegada o localhost en dev), validat.
    let redirectUrl: string;
    try {
      redirectUrl = resolveRedirectUrl(
        request.data?.redirectUrl as string | undefined
      );
    } catch {
      throw new HttpsError("invalid-argument", "redirect_url no permès.");
    }

    const addConnection = request.data?.newConnection === true;
    const requestedConnectionId = (
      request.data?.connectionId as string | undefined
    )?.trim();

    let connectionId: string;
    let target: { name: string; country: string };
    let existing: DocumentSnapshot | null = null;
    if (addConnection) {
      const name = (request.data?.aspspName as string | undefined)?.trim();
      if (!name) {
        throw new HttpsError("invalid-argument", "Tria el banc que vols connectar.");
      }
      target = { name, country: normalizeCountry(request.data?.aspspCountry ?? "ES") };
      connectionId = `${aspspSlug(name)}-${randomUUID()}`;
    } else {
      if (!requestedConnectionId) {
        throw new HttpsError("invalid-argument", "Falta la connexió a renovar.");
      }
      connectionId = requestedConnectionId;
      assertValidConnectionId(connectionId);
      existing = await db.doc(bankConnectionDoc(uid, connectionId)).get();
      if (!existing.exists) {
        throw new HttpsError("not-found", "Connexió bancària no trobada.");
      }
      const existingGroupId = existing.get("groupId") as string | undefined;
      const isLegacyDoc = !existingGroupId && connectionId === aspspSlug(LEGACY_ASPSP.name);
      if (existingGroupId !== groupId && !isLegacyDoc) {
        throw new HttpsError(
          "permission-denied",
          "Aquesta connexió bancària no pertany al grup actiu."
        );
      }
      target = {
        name: (existing.get("aspspName") as string | undefined) ?? LEGACY_ASPSP.name,
        country: (existing.get("aspspCountry") as string | undefined) ?? LEGACY_ASPSP.country,
      };
    }
    assertValidConnectionId(connectionId);

    const creds = credentialsFor(access);
    const aspsp = await findAspsp(db, creds, target.name, target.country);

    // Validesa: la màxima que admet l'ASPSP (o 90 dies si no la publica),
    // menys un marge. Demanar el màxim exacte dona 422 ("ASPSP does not
    // support consent validity more than N seconds"): quan la petició arriba,
    // ja l'hem passat per uns segons (verificat al sandbox).
    const fallbackSeconds = REQUESTED_CONSENT_DAYS * 24 * 60 * 60;
    const validSeconds = consentSecondsFor(aspsp.maximumConsentValidity ?? fallbackSeconds);
    const validUntil = new Date(Date.now() + validSeconds * 1000).toISOString();

    // State anti-CSRF d'un sol ús, desat abans d'iniciar la SCA.
    const state = randomUUID();
    const docRef = db.doc(bankConnectionDoc(uid, connectionId));
    await docRef.set(
      {
        connectionId,
        groupId,
        aspspName: aspsp.name,
        aspspCountry: aspsp.country,
        // Les desem per poder marcar les consultes com a "client present".
        requiredPsuHeaders: aspsp.requiredPsuHeaders,
        pendingState: state,
        pendingValidUntil: validUntil,
        // finalize comprova que l'aplicació no hagi canviat enmig de la SCA.
        pendingAppId: creds.appId,
        status: existing?.get("sessionId") ? existing.get("status") ?? "connected" : "authorizing",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    let auth: AuthResponse;
    try {
      const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);
      auth = await enableBankingFetch<AuthResponse>("/auth", {
        method: "POST",
        jwt,
        baseUrl: creds.baseUrl,
        body: {
          access: { valid_until: validUntil },
          aspsp: { name: aspsp.name, country: aspsp.country },
          state,
          redirect_url: redirectUrl,
          psu_type: PSU_TYPE,
        },
      });
    } catch (error) {
      // Un intent nou que EB rebutja no és una connexió real: no deixem un
      // document provisional invisible. En una renovació, conservem la sessió
      // anterior i només retirem l'estat temporal.
      if (addConnection) {
        await docRef.delete();
      } else {
        await docRef.set(
          {
            pendingState: FieldValue.delete(),
            pendingValidUntil: FieldValue.delete(),
            pendingAppId: FieldValue.delete(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }

      const status =
        error instanceof HttpsError &&
        error.details &&
        typeof error.details === "object" &&
        "status" in error.details
          ? (error.details as { status?: number }).status
          : undefined;
      const isLocalRedirect =
        redirectUrl.startsWith("http://localhost:") ||
        redirectUrl.startsWith("http://127.0.0.1:");
      if (status === 400 && isLocalRedirect) {
        throw new HttpsError(
          "failed-precondition",
          `Enable Banking ha rebutjat el callback local. Afegeix ${redirectUrl} ` +
            "als Redirect URLs de l'aplicació d'Enable Banking.",
          { status, redirectUrl }
        );
      }
      throw error;
    }

    if (!auth.url) {
      throw new HttpsError(
        "internal",
        "Enable Banking no ha retornat cap URL d'autorització."
      );
    }

    logger.info("Autorització bancària iniciada", {
      uid,
      groupId,
      app: shortAppId(creds.appId),
      source: creds.source,
      env: creds.env,
      aspsp: aspsp.name,
      validUntil,
    });

    // No retornem el `state` al client: viu a Firestore i tornarà via redirect.
    return {
      env: creds.env,
      authUrl: auth.url,
      aspspName: aspsp.name,
      connectionId,
      validUntil,
    };
  }
);
