import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  ASPSP_NAME,
  aspspSlug,
  bankConnectionDoc,
  ALL_EB_SECRETS,
  resolveEbCredentials,
} from "./config.js";
import {
  buildEnableBankingJwt,
  requireUid,
} from "./enableBanking.js";
import {
  EbAccount,
  ibansOf,
  maskIban,
  accountKeyOf,
  getAuthorizedSession,
  accountUidsOf,
  fetchAccountDetails,
} from "./ebAccounts.js";

/**
 * Fase 2 — llista els comptes linked (per al selector de "quins sincronitzar").
 * Retorna una clau estable (accountKey = identification_hash) + IBAN emmascarat
 * + nom, i la config de sync desada per l'usuari per a cada compte.
 */
export const listBankAccounts = onCall(
  {
    region: REGION,
    secrets: ALL_EB_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);
    const creds = resolveEbCredentials();
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

    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);
    const ctx = { jwt, baseUrl: creds.baseUrl };

    const session = await getAuthorizedSession(ctx, sessionId);
    const storedAccounts =
      (snap.get("accounts") as EbAccount[] | undefined) ?? [];
    const uids = accountUidsOf(session, storedAccounts);
    const accountConfig =
      (snap.get("accountConfig") as Record<string, unknown> | undefined) ?? {};

    const accounts = [];
    for (const u of uids) {
      const details = await fetchAccountDetails(ctx, u);
      const key = accountKeyOf(details);
      const cfg = (accountConfig[key] as Record<string, unknown> | undefined) ?? {};
      accounts.push({
        accountKey: key,
        ibanMasked: maskIban(ibansOf(details)[0] ?? ""),
        name: details.name ?? null,
        currency: details.currency ?? null,
        // Config de sync desada (si n'hi ha).
        sync: (cfg.sync as boolean | undefined) ?? false,
        centimAssetId: (cfg.centimAssetId as string | undefined) ?? null,
        syncStartDate: (cfg.syncStartDate as string | undefined) ?? null,
        lastSyncedDate: (cfg.lastSyncedDate as string | undefined) ?? null,
      });
    }

    logger.info("listBankAccounts OK", {
      uid,
      env: creds.env,
      accountCount: accounts.length,
    });

    return { env: creds.env, validUntil: snap.get("validUntil") ?? null, accounts };
  }
);
