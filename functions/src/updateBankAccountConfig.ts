import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  REGION,
  ASPSP_NAME,
  aspspSlug,
  bankConnectionDoc,
} from "./config.js";
import { requireUid } from "./enableBanking.js";

/**
 * Fase 2 — desa la config de sync d'un compte (quins comptes es sincronitzen,
 * a quin actiu de Cèntim, data d'inici) i el progrés incremental (lastSyncedDate).
 * S'escriu via Admin SDK: l'app mai toca directament el doc de connexió.
 */
export const updateBankAccountConfig = onCall(
  { region: REGION },
  async (request) => {
    const uid = requireUid(request);
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

    const slug = aspspSlug(ASPSP_NAME.value());
    const db = getFirestore();
    await db.doc(bankConnectionDoc(uid, slug)).set(
      {
        accountConfig: { [accountKey]: patch },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    logger.info("updateBankAccountConfig OK", {
      uid,
      fields: Object.keys(patch),
    });
    return { ok: true };
  }
);
