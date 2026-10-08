import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";

import { REGION, BANK_FUNCTION_SECRETS } from "./config.js";
import { requireUid } from "./enableBanking.js";
import { EbAccount, ibansOf, maskIban, accountKeyOf } from "./ebAccounts.js";
import {
  LEGACY_CONNECTION_ID,
  listBankConnectionDocs,
} from "./bankConnections.js";
import {
  connectionAppId,
  connectionReconnectState,
  groupConnectionDocs,
  legacyAppIdOrNull,
  requireBankAccess,
  wasEverConnected,
} from "./bankApp.js";

/**
 * Llista les connexions de l'usuari (per al selector "quins sincronitzar"),
 * amb l'estat de reconnexió de cadascuna, i els comptes accessibles del grup.
 *
 * NO fa cap crida a Enable Banking: els comptes complets ja es desen a
 * finalizeBankSession. Servir-los de la caché evita esgotar el rate limit d'EB.
 *
 * "Comptes accessibles" (groupAccounts) és la unió dels comptes de les
 * connexions ACTIVES de tots els membres del grup. Enable Banking no exposa
 * per API els comptes enllaçats al panell (GET /application no els retorna).
 */
export const listBankAccounts = onCall(
  { region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (request) => {
    const uid = requireUid(request);
    const db = getFirestore();
    const access = await requireBankAccess(db, uid);
    const legacyAppId = legacyAppIdOrNull();
    const currentAppId = access.app?.appId ?? legacyAppId ?? "";

    const { docs } = await listBankConnectionDocs(db, uid, LEGACY_CONNECTION_ID);
    // Totes les que han estat connectades alguna vegada (sigui quin sigui
    // l'estat: una renovació a mitges no pot amagar una connexió). Els
    // intents de SCA abandonats que no han connectat mai no es mostren.
    const visible = docs.filter((doc) => wasEverConnected(doc.data()));

    const connections = visible.map((snap) => {
      const stored = (snap.get("accounts") as EbAccount[] | undefined) ?? [];
      const accountConfig =
        (snap.get("accountConfig") as Record<string, unknown> | undefined) ?? {};
      const aspspName = (snap.get("aspspName") as string | undefined) ?? "CaixaBank";
      const connectionLabel =
        (snap.get("connectionLabel") as string | undefined) ??
        stored.map((account) => account.name?.trim()).find(Boolean) ??
        aspspName;
      const reconnect = connectionReconnectState(snap.data(), currentAppId, legacyAppId);

      const accounts = stored.map((acc) => {
        const key = accountKeyOf(acc);
        const cfg =
          (accountConfig[key] as Record<string, unknown> | undefined) ?? {};
        return {
          connectionId: snap.id,
          connectionLabel,
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

      return {
        connectionId: snap.id,
        label: connectionLabel,
        aspspName,
        aspspCountry: (snap.get("aspspCountry") as string | undefined) ?? "ES",
        validUntil: (snap.get("validUntil") as string | undefined) ?? null,
        status: (snap.get("status") as string | undefined) ?? "connected",
        needsReconnect: reconnect.needsReconnect,
        reconnectReason: reconnect.reason,
        accounts,
      };
    });
    const accounts = connections.flatMap((connection) => connection.accounts);
    const validUntil =
      connections
        .map((connection) => connection.validUntil)
        .filter((value): value is string => !!value)
        .sort()[0] ?? null;

    const groupAccounts = await accessibleGroupAccounts(
      db,
      access.groupId,
      currentAppId,
      legacyAppId
    );

    logger.info("listBankAccounts OK (cache)", {
      uid,
      connectionCount: connections.length,
      accountCount: accounts.length,
      groupAccountCount: groupAccounts.length,
    });

    return {
      // Camps legacy perquè les versions publicades de l'app continuïn funcionant.
      validUntil,
      accounts,
      connections,
      groupAccounts,
    };
  }
);

/**
 * Comptes que ja llegeix l'aplicació del grup: els de les connexions actives
 * de qualsevol membre, deduplicats. Sense IBAN sencer ni ids de sessió.
 */
async function accessibleGroupAccounts(
  db: FirebaseFirestore.Firestore,
  groupId: string,
  currentAppId: string,
  legacyAppId: string | null
) {
  const docs = await groupConnectionDocs(db, groupId);
  const active = docs.filter(
    (doc) =>
      !!doc.get("sessionId") &&
      doc.get("status") !== "inactive" &&
      doc.get("status") !== "needs-reconnect" &&
      connectionAppId(doc.data(), legacyAppId) === currentAppId
  );

  const memberUids = [...new Set(active.map((doc) => doc.ref.parent.parent?.id ?? ""))]
    .filter(Boolean);
  const profiles = await Promise.all(
    memberUids.map((memberUid) => db.doc(`users/${memberUid}`).get())
  );
  const memberName = new Map(
    profiles.map((profile) => [
      profile.id,
      (profile.get("name") as string | undefined)?.trim() ||
        (profile.get("email") as string | undefined) ||
        null,
    ])
  );

  const seen = new Set<string>();
  const out = [];
  for (const doc of active) {
    const memberUid = doc.ref.parent.parent?.id ?? "";
    for (const acc of (doc.get("accounts") as EbAccount[] | undefined) ?? []) {
      const key = accountKeyOf(acc);
      if (!key || seen.has(key)) continue;
      seen.add(key);
      out.push({
        ibanMasked: maskIban(ibansOf(acc)[0] ?? ""),
        name: acc.name ?? null,
        aspspName: (doc.get("aspspName") as string | undefined) ?? "CaixaBank",
        memberName: memberName.get(memberUid) ?? null,
      });
    }
  }
  return out;
}
