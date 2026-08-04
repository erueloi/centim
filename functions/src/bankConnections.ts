import {
  DocumentData,
  Firestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { bankConnectionsCollection } from "./config.js";

export interface UserBankConnections {
  groupId: string;
  docs: QueryDocumentSnapshot<DocumentData>[];
}

/** Grup actiu del propietari de les connexions. */
export async function currentBankGroupId(
  db: Firestore,
  uid: string
): Promise<string> {
  const profile = await db.doc(`users/${uid}`).get();
  const groupId = profile.get("currentGroupId") as string | undefined;
  if (!groupId) {
    throw new HttpsError(
      "failed-precondition",
      "No hi ha cap grup actiu per associar-hi la connexió bancària."
    );
  }
  return groupId;
}

/**
 * Connexions del grup actiu. El document legacy `caixabank`, que no tenia
 * groupId, s'associa al grup actual sense tocar sessionId, comptes ni config.
 */
export async function listBankConnectionDocs(
  db: Firestore,
  uid: string,
  legacyConnectionId: string
): Promise<UserBankConnections> {
  const groupId = await currentBankGroupId(db, uid);
  const snapshot = await db.collection(bankConnectionsCollection(uid)).get();
  const docs: QueryDocumentSnapshot<DocumentData>[] = [];

  for (const doc of snapshot.docs) {
    const docGroupId = doc.get("groupId") as string | undefined;
    const isLegacy = doc.id === legacyConnectionId && !docGroupId;
    if (docGroupId !== groupId && !isLegacy) continue;
    docs.push(doc);
    if (isLegacy) {
      await doc.ref.set({ groupId }, { merge: true });
    }
  }

  return { groupId, docs };
}

export function assertValidConnectionId(connectionId: string): void {
  if (!/^[a-z0-9][a-z0-9-]{0,99}$/.test(connectionId)) {
    throw new HttpsError("invalid-argument", "connectionId no vàlid.");
  }
}

/** Exigeix que una connexió concreta pertanyi al grup actiu de l'usuari. */
export async function requireBankConnectionDoc(
  db: Firestore,
  uid: string,
  connectionId: string,
  legacyConnectionId: string
): Promise<QueryDocumentSnapshot<DocumentData>> {
  assertValidConnectionId(connectionId);
  const { docs } = await listBankConnectionDocs(
    db,
    uid,
    legacyConnectionId
  );
  const doc = docs.find((candidate) => candidate.id === connectionId);
  if (!doc) {
    throw new HttpsError("not-found", "Connexió bancària no trobada.");
  }
  return doc;
}
