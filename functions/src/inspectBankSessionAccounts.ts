import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  ASPSP_NAME,
  aspspSlug,
  ALL_EB_SECRETS,
  resolveEbCredentials,
} from "./config.js";
import { buildEnableBankingJwt, requireUid } from "./enableBanking.js";
import {
  EbAccount,
  accountKeyOf,
  accountUidsOf,
  fetchAccountDetails,
  getAuthorizedSession,
  ibansOf,
  maskIban,
} from "./ebAccounts.js";
import { requireBankConnectionDoc } from "./bankConnections.js";

/**
 * Diagnòstic manual i de només lectura: consulta en directe quins comptes veu
 * la sessió actual d'Enable Banking. No actualitza la caché ni la configuració.
 */
export const inspectBankSessionAccounts = onCall(
  {
    region: REGION,
    secrets: ALL_EB_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);
    const slug = aspspSlug(ASPSP_NAME.value());
    const connectionId =
      (request.data?.connectionId as string | undefined)?.trim() || slug;
    const snap = await requireBankConnectionDoc(
      getFirestore(),
      uid,
      connectionId,
      slug
    );
    const sessionId = snap.get("sessionId") as string | undefined;
    if (!sessionId) {
      throw new HttpsError(
        "failed-precondition",
        "No hi ha cap sessió bancària. Connecta el banc primer.",
        { needsReauth: true }
      );
    }

    const creds = resolveEbCredentials();
    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);
    const session = await getAuthorizedSession(
      { jwt, baseUrl: creds.baseUrl },
      sessionId
    );

    // Sense fallback a la caché: aquesta Function ha de dir què retorna ara
    // mateix la sessió, no repetir els comptes que Cèntim ja tenia desats.
    const liveUids = [...new Set(accountUidsOf(session, []))];
    const stored = (snap.get("accounts") as EbAccount[] | undefined) ?? [];
    const storedKeys = new Set(stored.map(accountKeyOf).filter(Boolean));
    const accounts = [];

    for (const accountUid of liveUids) {
      const details = await fetchAccountDetails(
        { jwt, baseUrl: creds.baseUrl },
        accountUid
      );
      const key = accountKeyOf(details);
      accounts.push({
        ibanMasked: maskIban(ibansOf(details)[0] ?? ""),
        name: details.name ?? null,
        currency: details.currency ?? null,
        alreadyCached: key !== "" && storedKeys.has(key),
      });
    }

    logger.info("inspectBankSessionAccounts OK", {
      uid,
      connectionId,
      cachedAccountCount: stored.length,
      liveAccountCount: accounts.length,
    });

    return {
      connectionId,
      cachedAccountCount: stored.length,
      liveAccountCount: accounts.length,
      accounts,
    };
  }
);
