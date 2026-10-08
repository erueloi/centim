import {
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";

import { BANK_FUNCTION_SECRETS, REGION, bankAppDoc } from "./config.js";
import {
  EbAppCredentials,
  credentialsFor,
  deactivateMemberConnections,
  isLegacyGroup,
  legacyAppIdOrNull,
  loadGroupBankApp,
} from "./bankApp.js";

/** uids que eren a memberIds abans i ja no hi són. */
export function removedMembers(before: unknown, after: unknown): string[] {
  const asList = (value: unknown) =>
    Array.isArray(value) ? value.filter((v): v is string => typeof v === "string") : [];
  const remaining = new Set(asList(after));
  return [...new Set(asList(before))].filter((uid) => !remaining.has(uid));
}

/**
 * Quan algú surt d'un grup (o l'owner el treu), les seves connexions bancàries
 * d'aquell grup queden inactives i se'n revoquen les sessions. És un trigger
 * perquè memberIds l'escriu l'app directament (regles), no cap Function.
 */
export const onGroupMembersChanged = onDocumentUpdated(
  { document: "groups/{groupId}", region: REGION, secrets: BANK_FUNCTION_SECRETS },
  async (event) => {
    const groupId = event.params.groupId;
    const removed = removedMembers(
      event.data?.before.get("memberIds"),
      event.data?.after.get("memberIds")
    );
    if (removed.length === 0) return;

    const db = getFirestore();
    let creds: EbAppCredentials | null = null;
    try {
      const app = await loadGroupBankApp(db, groupId);
      if (app || isLegacyGroup(groupId)) {
        creds = credentialsFor({ groupId, app, legacy: !app });
      }
    } catch {
      creds = null; // sense credencials: només es marquen com a inactives
    }
    const legacyAppId = legacyAppIdOrNull();

    let total = 0;
    for (const uid of removed) {
      total += await deactivateMemberConnections(db, groupId, uid, creds, legacyAppId);
    }
    logger.info("Connexions bancàries de membres sortints desactivades", {
      groupId,
      removedMembers: removed.length,
      connections: total,
    });
  }
);

/** Si s'esborra un grup, se n'esborren també les credencials bancàries. */
export const onGroupDeleted = onDocumentDeleted(
  { document: "groups/{groupId}", region: REGION },
  async (event) => {
    const groupId = event.params.groupId;
    await getFirestore().doc(bankAppDoc(groupId)).delete();
    logger.info("Credencials bancàries d'un grup esborrat eliminades", { groupId });
  }
);
