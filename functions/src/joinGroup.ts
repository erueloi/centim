import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { FieldValue, getFirestore, type Firestore } from "firebase-admin/firestore";

import { REGION } from "./config.js";
import { requireUid } from "./auth.js";

/** Mateix format que genera l'app (GroupRepository._generateInviteCode). */
const INVITE_CODE_PATTERN = /^[A-Z0-9]{6}$/;

export interface JoinGroupResult {
  groupId: string;
  groupName: string;
}

/**
 * Lògica d'unir-se a un grup amb el codi d'invitació. Separada del handler
 * perquè es pugui provar contra l'emulador de Firestore.
 *
 * Les regles no deixen llistar grups ni afegir-se a `memberIds`: aquesta és
 * l'única porta d'entrada a una llar, i exigeix conèixer el codi.
 */
export async function joinGroupWithCodeImpl(
  db: Firestore,
  uid: string,
  rawCode: unknown
): Promise<JoinGroupResult> {
  const code = typeof rawCode === "string" ? rawCode.trim().toUpperCase() : "";
  if (!INVITE_CODE_PATTERN.test(code)) {
    throw new HttpsError(
      "invalid-argument",
      "El codi d'invitació ha de tenir 6 lletres o números."
    );
  }

  const matches = await db
    .collection("groups")
    .where("inviteCode", "==", code)
    .limit(2)
    .get();
  if (matches.empty) {
    throw new HttpsError(
      "not-found",
      "No hi ha cap grup amb aquest codi d'invitació."
    );
  }
  if (matches.size > 1) {
    // Els codis es generen al client sense comprovar unicitat; és molt
    // improbable, però no unim ningú a l'atzar a una de dues llars.
    logger.error("Codi d'invitació duplicat", { groupCount: matches.size });
    throw new HttpsError(
      "failed-precondition",
      "Aquest codi d'invitació no és únic. Demana a qui t'ha convidat que ho revisi."
    );
  }

  const groupRef = matches.docs[0].ref;
  const userRef = db.doc(`users/${uid}`);

  const groupName = await db.runTransaction(async (tx) => {
    const group = await tx.get(groupRef);
    if (!group.exists) {
      throw new HttpsError(
        "not-found",
        "No hi ha cap grup amb aquest codi d'invitació."
      );
    }
    const memberIds = (group.get("memberIds") as string[] | undefined) ?? [];
    if (!memberIds.includes(uid)) {
      tx.update(groupRef, { memberIds: FieldValue.arrayUnion(uid) });
    }
    tx.set(userRef, { currentGroupId: groupRef.id }, { merge: true });
    return (group.get("name") as string | undefined) ?? "";
  });

  return { groupId: groupRef.id, groupName };
}

export const joinGroupWithCode = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const result = await joinGroupWithCodeImpl(
    getFirestore(),
    uid,
    (request.data as { code?: unknown } | undefined)?.code
  );
  logger.info("joinGroupWithCode OK", { uid, groupId: result.groupId });
  return result;
});
