import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  ASPSP_NAME,
  aspspSlug,
  bankConnectionDoc,
} from "./config.js";
import { requireUid } from "./enableBanking.js";
import { EbAccount, ibansOf, maskIban, accountKeyOf } from "./ebAccounts.js";

/**
 * Fase 2 — llista els comptes linked (per al selector "quins sincronitzar").
 *
 * NO fa cap crida a Enable Banking: els comptes complets (uid, IBAN,
 * identification_hash, nom) ja es desen a finalizeBankSession des de la
 * resposta de POST /sessions. Servir-los de la caché evita esgotar el rate
 * limit d'EB (429) cada cop que s'obre la pantalla de configuració.
 */
export const listBankAccounts = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const slug = aspspSlug(ASPSP_NAME.value());

  const db = getFirestore();
  const snap = await db.doc(bankConnectionDoc(uid, slug)).get();
  const sessionId = snap.get("sessionId") as string | undefined;
  if (!sessionId) {
    throw new HttpsError(
      "failed-precondition",
      "No hi ha cap sessió bancària. Connecta el banc primer.",
      { needsReauth: true }
    );
  }

  const stored = (snap.get("accounts") as EbAccount[] | undefined) ?? [];
  const accountConfig =
    (snap.get("accountConfig") as Record<string, unknown> | undefined) ?? {};

  const accounts = stored.map((acc) => {
    const key = accountKeyOf(acc);
    const cfg = (accountConfig[key] as Record<string, unknown> | undefined) ?? {};
    return {
      accountKey: key,
      ibanMasked: maskIban(ibansOf(acc)[0] ?? ""),
      name: acc.name ?? null,
      currency: acc.currency ?? null,
      sync: (cfg.sync as boolean | undefined) ?? false,
      centimAssetId: (cfg.centimAssetId as string | undefined) ?? null,
      syncStartDate: (cfg.syncStartDate as string | undefined) ?? null,
      lastSyncedDate: (cfg.lastSyncedDate as string | undefined) ?? null,
    };
  });

  logger.info("listBankAccounts OK (cache)", {
    uid,
    accountCount: accounts.length,
  });

  return {
    validUntil: snap.get("validUntil") ?? null,
    accounts,
  };
});
