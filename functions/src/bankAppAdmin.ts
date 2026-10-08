import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { BANK_FUNCTION_SECRETS, REGION, bankAppDoc } from "./config.js";
import { requireUid } from "./auth.js";
import { currentBankGroupId } from "./bankConnections.js";
import {
  EbAppCredentials,
  credentialsFor,
  getAspsps,
  isLegacyGroup,
  legacyAppIdOrNull,
  loadGroupBankApp,
  normalizeCountry,
  reconcileGroupConnections,
  requireBankAccess,
  requireGroupOwner,
  shortAppId,
  storeGroupBankApp,
  validateBankAppCredentials,
} from "./bankApp.js";

/**
 * Estat de l'aplicació d'Enable Banking del grup, per a qualsevol membre.
 * MAI inclou la clau privada.
 */
export const getBankSetup = onCall(
  { region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    const groupId = await currentBankGroupId(db, uid);
    const [group, app] = await Promise.all([
      db.doc(`groups/${groupId}`).get(),
      loadGroupBankApp(db, groupId),
    ]);
    const isOwner = group.get("ownerId") === uid;

    if (app) {
      return {
        configured: true,
        source: "group",
        appIdShort: shortAppId(app.appId),
        env: app.env,
        appName: app.appName,
        validatedAt: (app.validatedAt as Timestamp | undefined)?.toDate().toISOString() ?? null,
        isOwner,
      };
    }
    const legacy = isLegacyGroup(groupId);
    return {
      configured: legacy,
      source: legacy ? "legacy" : null,
      appIdShort: null,
      env: null,
      appName: null,
      validatedAt: null,
      isOwner,
    };
  }
);

/**
 * L'owner desa (o substitueix) l'aplicació del grup. Es valida amb una crida
 * real a GET /application i es desa xifrada. La resposta no inclou mai la clau.
 */
export const saveBankAppCredentials = onCall(
  { region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    const groupId = await requireGroupOwner(db, uid);

    const validated = await validateBankAppCredentials(
      request.data?.appId,
      request.data?.pem
    );

    // Credencials anteriors (en memòria) per revocar les sessions que deixen
    // de ser vàlides. Si no es poden obtenir, només es marquen.
    const previousApp = await loadGroupBankApp(db, groupId);
    let previousCreds: EbAppCredentials | null = null;
    try {
      if (previousApp) {
        previousCreds = credentialsFor({ groupId, app: previousApp, legacy: false });
      } else if (isLegacyGroup(groupId)) {
        previousCreds = credentialsFor({ groupId, app: null, legacy: true });
      }
    } catch {
      previousCreds = null;
    }

    await storeGroupBankApp(db, groupId, uid, validated);
    const result = await reconcileGroupConnections(db, groupId, {
      newAppId: validated.appId,
      previousCreds,
      legacyAppId: legacyAppIdOrNull(),
      reason: "app-changed",
    });

    logger.info("Aplicació bancària del grup desada", {
      uid,
      groupId,
      appId: shortAppId(validated.appId),
      env: validated.env,
      ...result,
    });
    return {
      appIdShort: shortAppId(validated.appId),
      env: validated.env,
      appName: validated.appName,
      connectionsKept: result.kept,
      connectionsToReconnect: result.reconnect,
    };
  }
);

/**
 * L'owner elimina l'aplicació del grup: se'n revoquen les sessions i les
 * connexions passen a "cal reconnectar".
 */
export const deleteBankAppCredentials = onCall(
  { region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    const groupId = await requireGroupOwner(db, uid);
    const app = await loadGroupBankApp(db, groupId);
    if (!app) return { deleted: false, connectionsToReconnect: 0 };

    let creds: EbAppCredentials | null = null;
    try {
      creds = credentialsFor({ groupId, app, legacy: false });
    } catch {
      creds = null;
    }
    const result = await reconcileGroupConnections(db, groupId, {
      newAppId: null,
      previousCreds: creds,
      legacyAppId: legacyAppIdOrNull(),
      reason: "app-removed",
    });
    await db.doc(bankAppDoc(groupId)).delete();

    logger.info("Aplicació bancària del grup eliminada", {
      uid,
      groupId,
      appId: shortAppId(app.appId),
      ...result,
    });
    return { deleted: true, connectionsToReconnect: result.reconnect };
  }
);

/** Bancs disponibles al país (només els que admeten clients particulars). */
export const listAspsps = onCall(
  { region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    const access = await requireBankAccess(db, uid);
    const country = normalizeCountry(request.data?.country ?? "ES");
    const aspsps = await getAspsps(db, credentialsFor(access), country);
    return {
      country,
      aspsps: aspsps
        .filter((a) => a.psuTypes.length === 0 || a.psuTypes.includes("personal"))
        .map((a) => ({
          name: a.name,
          country: a.country,
          logo: a.logo,
          beta: a.beta,
          maximumConsentValidity: a.maximumConsentValidity,
        })),
    };
  }
);
