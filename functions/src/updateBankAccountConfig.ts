import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, BANK_FUNCTION_SECRETS } from "./config.js";
import { requireUid } from "./enableBanking.js";
import { EbAccount, accountKeyOf } from "./ebAccounts.js";
import {
  LEGACY_CONNECTION_ID,
  listBankConnectionDocs,
} from "./bankConnections.js";
import { requireBankAccess } from "./bankApp.js";

/**
 * Fase 2 — desa la config de sync d'un compte (quins comptes es sincronitzen,
 * a quin actiu de Cèntim, data d'inici) i el progrés incremental (lastSyncedDate).
 * S'escriu via Admin SDK: l'app mai toca directament el doc de connexió.
 */
export const updateBankAccountConfig = onCall(
  { region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    await requireBankAccess(db, uid);
    const accountKey = (request.data?.accountKey as string | undefined)?.trim();
    if (!accountKey) {
      throw new HttpsError("invalid-argument", "Falta accountKey.");
    }

    // Només acceptem camps coneguts (no es pot escriure res sensible).
    const patch: Record<string, unknown> = {};
    if (typeof request.data?.sync === "boolean") patch.sync = request.data.sync;
    if ("centimAssetId" in (request.data ?? {})) {
      patch.centimAssetId = request.data.centimAssetId ?? null;
    }
    if ("syncStartDate" in (request.data ?? {})) {
      patch.syncStartDate = request.data.syncStartDate ?? null;
    }
    if ("lastSyncedDate" in (request.data ?? {})) {
      patch.lastSyncedDate = request.data.lastSyncedDate ?? null;
    }
    if (Object.keys(patch).length === 0) {
      throw new HttpsError("invalid-argument", "Cap camp de config a desar.");
    }

    const requestedConnectionId = (
      request.data?.connectionId as string | undefined
    )?.trim();
    const { docs } = await listBankConnectionDocs(db, uid, LEGACY_CONNECTION_ID);
    const candidates = requestedConnectionId
      ? docs.filter((doc) => doc.id === requestedConnectionId)
      : docs;
    const target = candidates.find((doc) => {
      const accounts = (doc.get("accounts") as EbAccount[] | undefined) ?? [];
      return accounts.some((account) => accountKeyOf(account) === accountKey);
    });
    if (!target) {
      throw new HttpsError(
        "not-found",
        "No s'ha trobat el compte dins de la connexió indicada."
      );
    }

    await target.ref.set(
      {
        accountConfig: { [accountKey]: patch },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    logger.info("updateBankAccountConfig OK", {
      uid,
      connectionId: target.id,
      fields: Object.keys(patch),
    });
    return { ok: true };
  }
);
