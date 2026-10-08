import { createPrivateKey } from "node:crypto";
import {
  DocumentData,
  FieldValue,
  Firestore,
  QueryDocumentSnapshot,
  Timestamp,
} from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError } from "firebase-functions/v2/https";

import {
  BANK_ALLOWED_GROUP_IDS,
  BANK_APP_MASTER_KEYRING,
  EB_API_BASE_URL,
  PRODUCTION_CALLBACK_URL,
  aspspCacheDoc,
  bankAppDoc,
  resolveEbCredentials,
} from "./config.js";
import {
  EncryptedSecret,
  decryptSecret,
  encryptSecret,
  parseKeyring,
} from "./bankAppCrypto.js";
import { buildEnableBankingJwt, enableBankingFetch } from "./enableBanking.js";
import { currentBankGroupId, parseAllowedGroupIds } from "./bankConnections.js";

/** Motius (`details.reason`) que l'app fa servir per decidir què mostra. */
export const NO_BANK_APP = "no-bank-app";
export const APP_CHANGED = "app-changed";
export const NOT_GROUP_OWNER = "not-group-owner";

export type EbEnv = "sandbox" | "production";

/** Document bank_apps/{groupId}. Les regles el deneguen a tots els clients. */
export interface StoredBankApp {
  appId: string;
  env: EbEnv;
  appName: string | null;
  encryptedKey: EncryptedSecret;
  validatedAt: Timestamp;
  validatedBy: string;
}

/** Credencials a punt per signar JWT. Només existeixen en memòria. */
export interface EbAppCredentials {
  appId: string;
  pem: string;
  env: EbEnv;
  baseUrl: string;
  /** "group": aplicació pròpia del grup; "legacy": l'aplicació global (transició). */
  source: "group" | "legacy";
}

/** Resultat del control d'accés de les Functions bancàries. */
export interface BankAccess {
  groupId: string;
  app: StoredBankApp | null;
  /** Grup de BANK_ALLOWED_GROUP_IDS sense aplicació pròpia: fa servir la global. */
  legacy: boolean;
}

// ---------------------------------------------------------------------------
// Aplicació del grup
// ---------------------------------------------------------------------------

export async function loadGroupBankApp(
  db: Firestore,
  groupId: string
): Promise<StoredBankApp | null> {
  const snap = await db.doc(bankAppDoc(groupId)).get();
  return snap.exists ? (snap.data() as StoredBankApp) : null;
}

/** TRANSICIÓ: grups que encara poden fer servir l'aplicació global. */
export function isLegacyGroup(groupId: string): boolean {
  return parseAllowedGroupIds(BANK_ALLOWED_GROUP_IDS.value()).has(groupId);
}

/**
 * App id de l'aplicació global (transició), o null si els seus secrets ja no
 * hi són. Serveix per reconèixer les connexions antigues, que no tenen appId.
 */
export function legacyAppIdOrNull(): string | null {
  try {
    return resolveEbCredentials().appId.trim() || null;
  } catch {
    return null;
  }
}

/**
 * Porta d'entrada de TOTES les Functions bancàries (abans de qualsevol crida a
 * Enable Banking): l'usuari ha de ser de debò membre del seu grup actiu, i el
 * grup ha de tenir aplicació pròpia o ser de la llista de transició.
 */
export async function requireBankAccess(
  db: Firestore,
  uid: string
): Promise<BankAccess> {
  const groupId = await currentBankGroupId(db, uid);
  const app = await loadGroupBankApp(db, groupId);
  if (app) return { groupId, app, legacy: false };
  if (isLegacyGroup(groupId)) return { groupId, app: null, legacy: true };
  throw new HttpsError(
    "failed-precondition",
    "El teu grup encara no té configurada la connexió bancària.",
    { reason: NO_BANK_APP }
  );
}

/** Desxifra (en memòria) les credencials del grup. */
export function credentialsFor(access: BankAccess): EbAppCredentials {
  if (access.app) {
    const keyring = parseKeyring(BANK_APP_MASTER_KEYRING.value());
    return {
      appId: access.app.appId,
      pem: decryptSecret(access.app.encryptedKey, access.groupId, keyring),
      env: access.app.env,
      baseUrl: EB_API_BASE_URL,
      source: "group",
    };
  }
  const legacy = resolveEbCredentials();
  return {
    appId: legacy.appId,
    pem: legacy.pem,
    env: legacy.env,
    baseUrl: legacy.baseUrl,
    source: "legacy",
  };
}

/** Exigeix que l'usuari sigui l'owner del seu grup actiu. Retorna el groupId. */
export async function requireGroupOwner(db: Firestore, uid: string): Promise<string> {
  const groupId = await currentBankGroupId(db, uid);
  const group = await db.doc(`groups/${groupId}`).get();
  if (group.get("ownerId") !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Només l'owner del grup pot configurar la connexió bancària.",
      { reason: NOT_GROUP_OWNER }
    );
  }
  return groupId;
}

// ---------------------------------------------------------------------------
// Validació de credencials noves
// ---------------------------------------------------------------------------

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_PEM_CHARS = 16_000;

interface EbApplication {
  name?: string;
  environment?: string;
  active?: boolean;
  redirect_urls?: string[];
}

export interface ValidatedBankApp {
  appId: string;
  /** Clau normalitzada a PKCS#8. MAI s'ha de retornar ni registrar. */
  pem: string;
  env: EbEnv;
  appName: string | null;
}

/**
 * Normalitza la clau a PKCS#8 (accepta també PKCS#1) i comprova que sigui RSA.
 * Els errors no inclouen mai el contingut de la clau.
 */
export function normalizePrivateKey(raw: string): string {
  const input = (raw ?? "").trim();
  if (!input || input.length > MAX_PEM_CHARS || !input.includes("PRIVATE KEY")) {
    throw new HttpsError(
      "invalid-argument",
      "La clau privada no és vàlida. Ha de ser el fitxer .pem que dona Enable Banking."
    );
  }
  try {
    const key = createPrivateKey({ key: input, format: "pem" });
    if (key.asymmetricKeyType !== "rsa") throw new Error("not rsa");
    return key.export({ type: "pkcs8", format: "pem" }).toString();
  } catch {
    throw new HttpsError(
      "invalid-argument",
      "La clau privada no és vàlida. Ha de ser una clau RSA en format PEM."
    );
  }
}

/** Cert si l'aplicació té registrat un callback de Cèntim vàlid per al seu entorn. */
export function hasCentimCallback(redirectUrls: string[], env: EbEnv): boolean {
  return redirectUrls.some((url) => {
    if (url === PRODUCTION_CALLBACK_URL) return true;
    if (env !== "sandbox") return false;
    try {
      const u = new URL(url);
      return (
        (u.hostname === "localhost" || u.hostname === "127.0.0.1") &&
        u.pathname === "/bank-callback"
      );
    } catch {
      return false;
    }
  });
}

/**
 * Comprova les credencials amb una crida real a GET /application: la clau i
 * l'app id han de casar, l'aplicació ha d'estar activa i tenir el callback.
 */
export async function validateBankAppCredentials(
  rawAppId: unknown,
  rawPem: unknown
): Promise<ValidatedBankApp> {
  const appId = typeof rawAppId === "string" ? rawAppId.trim().toLowerCase() : "";
  if (!UUID_PATTERN.test(appId)) {
    throw new HttpsError(
      "invalid-argument",
      "L'id de l'aplicació no és vàlid: és un identificador de 36 caràcters (UUID)."
    );
  }
  const pem = normalizePrivateKey(typeof rawPem === "string" ? rawPem : "");

  let application: EbApplication;
  try {
    const jwt = await buildEnableBankingJwt(appId, pem);
    application = await enableBankingFetch<EbApplication>("/application", {
      jwt,
      baseUrl: EB_API_BASE_URL,
    });
  } catch (error) {
    if (error instanceof HttpsError && error.code === "permission-denied") {
      throw new HttpsError(
        "invalid-argument",
        "Enable Banking no reconeix aquest id d'aplicació amb aquesta clau. " +
          "Comprova que siguin de la mateixa aplicació."
      );
    }
    throw error;
  }

  const env: EbEnv =
    (application.environment ?? "").toUpperCase() === "PRODUCTION"
      ? "production"
      : "sandbox";
  if (application.active !== true) {
    throw new HttpsError(
      "failed-precondition",
      "L'aplicació encara no està activa al panell d'Enable Banking."
    );
  }
  if (!hasCentimCallback(application.redirect_urls ?? [], env)) {
    throw new HttpsError(
      "failed-precondition",
      `L'aplicació no té registrada la redirect URL ${PRODUCTION_CALLBACK_URL}. ` +
        "Afegeix-la al panell d'Enable Banking i torna-ho a provar."
    );
  }
  return { appId, pem, env, appName: application.name?.trim() || null };
}

/** Desa (xifrada) l'aplicació del grup. */
export async function storeGroupBankApp(
  db: Firestore,
  groupId: string,
  uid: string,
  validated: ValidatedBankApp
): Promise<void> {
  const keyring = parseKeyring(BANK_APP_MASTER_KEYRING.value());
  await db.doc(bankAppDoc(groupId)).set({
    appId: validated.appId,
    env: validated.env,
    appName: validated.appName,
    encryptedKey: encryptSecret(validated.pem, groupId, keyring),
    validatedAt: FieldValue.serverTimestamp(),
    validatedBy: uid,
  });
}

// ---------------------------------------------------------------------------
// Connexions del grup
// ---------------------------------------------------------------------------

/** Totes les connexions bancàries del grup, de tots els membres. */
export async function groupConnectionDocs(
  db: Firestore,
  groupId: string
): Promise<QueryDocumentSnapshot<DocumentData>[]> {
  const snap = await db
    .collectionGroup("bank_connections")
    .where("groupId", "==", groupId)
    .get();
  return snap.docs;
}

/**
 * Aplicació amb què es va crear la connexió. Les anteriors a la fase 1 no
 * tenen appId: es van crear amb l'aplicació global.
 */
export function connectionAppId(
  conn: DocumentData,
  legacyAppId: string | null
): string | null {
  return (conn.appId as string | undefined) ?? legacyAppId;
}

/** Estat de reconnexió d'una connexió respecte de l'aplicació actual del grup. */
export function connectionReconnectState(
  conn: DocumentData,
  currentAppId: string,
  legacyAppId: string | null
): { needsReconnect: boolean; reason: string | null } {
  const status = conn.status as string | undefined;
  if (status === "inactive") {
    return { needsReconnect: true, reason: (conn.inactiveReason as string) ?? "inactive" };
  }
  if (status === "needs-reconnect") {
    return { needsReconnect: true, reason: (conn.reconnectReason as string) ?? APP_CHANGED };
  }
  if (connectionAppId(conn, legacyAppId) !== currentAppId) {
    return { needsReconnect: true, reason: APP_CHANGED };
  }
  return { needsReconnect: false, reason: null };
}

/**
 * Revoca una sessió a Enable Banking (DELETE /sessions/{id}). És de millor
 * esforç: un error només queda al log (sense ids de sessió) i no atura res.
 */
export async function revokeSession(
  creds: EbAppCredentials,
  sessionId: string,
  context: Record<string, unknown>
): Promise<boolean> {
  try {
    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);
    await enableBankingFetch(`/sessions/${encodeURIComponent(sessionId)}`, {
      method: "DELETE",
      jwt,
      baseUrl: creds.baseUrl,
    });
    return true;
  } catch (error) {
    logger.warn("No s'ha pogut revocar una sessió bancària", {
      ...context,
      code: error instanceof HttpsError ? error.code : "unknown",
    });
    return false;
  }
}

/**
 * Després de canviar o eliminar l'aplicació del grup: les connexions creades
 * amb una altra aplicació passen a "cal reconnectar" (i se'n revoca la sessió
 * si tenim les credencials amb què es va crear). Les antigues sense appId que
 * coincideixen amb la nova aplicació (migració amb el mateix app id) es
 * marquen amb l'appId i continuen funcionant sense reconnectar.
 */
export async function reconcileGroupConnections(
  db: Firestore,
  groupId: string,
  opts: {
    newAppId: string | null;
    previousCreds: EbAppCredentials | null;
    legacyAppId: string | null;
    reason: string;
  }
): Promise<{ kept: number; reconnect: number; revoked: number }> {
  let kept = 0;
  let reconnect = 0;
  let revoked = 0;
  for (const doc of await groupConnectionDocs(db, groupId)) {
    const conn = doc.data();
    if (conn.status === "inactive") continue;
    const appId = connectionAppId(conn, opts.legacyAppId);
    if (opts.newAppId && appId === opts.newAppId) {
      if (!conn.appId) await doc.ref.set({ appId: opts.newAppId }, { merge: true });
      kept++;
      continue;
    }
    const sessionId = conn.sessionId as string | undefined;
    if (sessionId && opts.previousCreds && appId === opts.previousCreds.appId) {
      if (await revokeSession(opts.previousCreds, sessionId, { groupId, connectionId: doc.id })) {
        revoked++;
      }
    }
    await doc.ref.set(
      {
        status: "needs-reconnect",
        reconnectReason: opts.reason,
        sessionId: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    reconnect++;
  }
  return { kept, reconnect, revoked };
}

/**
 * Un membre ha sortit del grup (o l'han tret): les seves connexions d'aquell
 * grup queden inactives i, si podem, se'n revoquen les sessions.
 */
export async function deactivateMemberConnections(
  db: Firestore,
  groupId: string,
  uid: string,
  creds: EbAppCredentials | null,
  legacyAppId: string | null
): Promise<number> {
  const snap = await db
    .collection(`users/${uid}/bank_connections`)
    .where("groupId", "==", groupId)
    .get();
  for (const doc of snap.docs) {
    const conn = doc.data();
    const sessionId = conn.sessionId as string | undefined;
    if (sessionId && creds && connectionAppId(conn, legacyAppId) === creds.appId) {
      await revokeSession(creds, sessionId, { groupId, connectionId: doc.id });
    }
    await doc.ref.set(
      {
        status: "inactive",
        inactiveReason: "left-group",
        sessionId: FieldValue.delete(),
        pendingState: FieldValue.delete(),
        pendingValidUntil: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  return snap.size;
}

// ---------------------------------------------------------------------------
// Catàleg d'ASPSP (bancs), en memòria cau 24 h a aspsp_cache/{env}_{country}
// ---------------------------------------------------------------------------

export interface AspspInfo {
  name: string;
  country: string;
  logo: string | null;
  psuTypes: string[];
  maximumConsentValidity: number | null;
  requiredPsuHeaders: string[];
  beta: boolean;
}

const ASPSP_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const COUNTRY_PATTERN = /^[A-Z]{2}$/;

export function normalizeCountry(raw: unknown): string {
  const country = typeof raw === "string" ? raw.trim().toUpperCase() : "";
  if (!COUNTRY_PATTERN.test(country)) {
    throw new HttpsError("invalid-argument", "El codi de país no és vàlid.");
  }
  return country;
}

interface EbAspsp {
  name: string;
  country: string;
  logo?: string;
  psu_types?: string[];
  maximum_consent_validity?: number;
  required_psu_headers?: string[];
  beta?: boolean;
}

export async function getAspsps(
  db: Firestore,
  creds: EbAppCredentials,
  country: string
): Promise<AspspInfo[]> {
  const ref = db.doc(aspspCacheDoc(creds.env, country));
  const cached = await ref.get();
  const fetchedAt = cached.get("fetchedAt") as Timestamp | undefined;
  if (cached.exists && fetchedAt && Date.now() - fetchedAt.toMillis() < ASPSP_CACHE_TTL_MS) {
    return cached.get("aspsps") as AspspInfo[];
  }

  const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);
  const resp = await enableBankingFetch<{ aspsps?: EbAspsp[] }>("/aspsps", {
    jwt,
    baseUrl: creds.baseUrl,
    query: { country },
  });
  const aspsps: AspspInfo[] = (resp.aspsps ?? [])
    .filter((a) => a.country === country)
    .map((a) => ({
      name: a.name,
      country: a.country,
      logo: a.logo ?? null,
      psuTypes: a.psu_types ?? [],
      maximumConsentValidity: a.maximum_consent_validity ?? null,
      requiredPsuHeaders: a.required_psu_headers ?? [],
      beta: a.beta === true,
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
  await ref.set({ fetchedAt: FieldValue.serverTimestamp(), aspsps });
  return aspsps;
}

/** Busca un banc pel nom exacte dins del catàleg del país. */
export async function findAspsp(
  db: Firestore,
  creds: EbAppCredentials,
  name: string,
  country: string
): Promise<AspspInfo> {
  const aspsps = await getAspsps(db, creds, country);
  const target = name.trim().toLowerCase();
  const aspsp = aspsps.find((a) => a.name.toLowerCase() === target);
  if (!aspsp) {
    throw new HttpsError(
      "not-found",
      `${name} no està disponible ara mateix a Enable Banking.`
    );
  }
  return aspsp;
}

/** App id escurçat per mostrar-lo a la UI. */
export function shortAppId(appId: string): string {
  return appId.length > 8 ? `${appId.slice(0, 8)}…` : appId;
}
