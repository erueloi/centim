import {
  DocumentData,
  Firestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { BANK_ALLOWED_GROUP_IDS, bankConnectionsCollection } from "./config.js";

/** Motiu a `details.reason` perquè l'app distingeixi aquest bloqueig. */
export const BANK_NOT_ENABLED = "bank-not-enabled";

/** Interpreta la llista d'ids separats per comes (ignora espais i buits). */
export function parseAllowedGroupIds(raw: string | undefined): Set<string> {
  return new Set(
    (raw ?? "")
      .split(",")
      .map((id) => id.trim())
      .filter(Boolean)
  );
}

/**
 * Porta d'entrada de TOTES les Functions bancàries: s'ha de cridar abans de
 * qualsevol crida a Enable Banking o lectura de connexions.
 *
 * Exigeix que l'usuari sigui de debò membre del seu grup actiu (vegeu
 * [currentBankGroupId]) i que aquest grup sigui a BANK_ALLOWED_GROUP_IDS.
 * Retorna el groupId verificat.
 */
export async function requireBankAccess(
  db: Firestore,
  uid: string,
  allowedGroupIds: Set<string> = parseAllowedGroupIds(
    BANK_ALLOWED_GROUP_IDS.value()
  )
): Promise<string> {
  const groupId = await currentBankGroupId(db, uid);
  if (!allowedGroupIds.has(groupId)) {
    throw new HttpsError(
      "permission-denied",
      "La connexió bancària encara no està disponible per al teu grup.",
      { reason: BANK_NOT_ENABLED }
    );
  }
  return groupId;
}

export interface UserBankConnections {
  groupId: string;
  docs: QueryDocumentSnapshot<DocumentData>[];
}

/**
 * Grup actiu del propietari de les connexions. El `currentGroupId` el pot
 * escriure el mateix usuari, així que cal verificar que n'és membre de debò.
 */
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
  const group = await db.doc(`groups/${groupId}`).get();
  const memberIds = (group.get("memberIds") as string[] | undefined) ?? [];
  if (!memberIds.includes(uid)) {
    throw new HttpsError(
      "permission-denied",
      "No ets membre del grup actiu."
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
