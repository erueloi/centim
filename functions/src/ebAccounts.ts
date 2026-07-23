import { HttpsError } from "firebase-functions/v2/https";
import { enableBankingFetch } from "./enableBanking.js";

/** Objecte de compte tal com el retorna /accounts/{uid}/details i POST /sessions. */
export interface EbAccount {
  uid?: string;
  account_id?: { iban?: string };
  all_account_ids?: { identification?: string; scheme_name?: string }[];
  name?: string;
  currency?: string;
  /** Hash estable entre sessions (l'uid canvia a cada re-auth). Clau de config. */
  identification_hash?: string;
}

/** Clau estable per identificar un compte entre sessions/re-auths. */
export function accountKeyOf(acc: EbAccount): string {
  return acc.identification_hash ?? acc.uid ?? "";
}

interface EbSession {
  status?: string;
  /** GET /sessions/{id}: llista d'UID (strings). */
  accounts?: unknown[];
  /** GET /sessions/{id}: objectes de compte (sense IBAN fiable). */
  accounts_data?: EbAccount[];
}

interface EbCtx {
  jwt: string;
  baseUrl: string;
}

/** Recull els IBAN d'un compte (account_id.iban + all_account_ids IBAN), deduplicats. */
export function ibansOf(acc: EbAccount): string[] {
  const out: string[] = [];
  if (acc.account_id?.iban) out.push(acc.account_id.iban);
  for (const a of acc.all_account_ids ?? []) {
    if (
      a.identification &&
      (a.scheme_name?.toUpperCase() === "IBAN" || a.identification.length > 10)
    ) {
      out.push(a.identification);
    }
  }
  return [...new Set(out.map((s) => s.replace(/\s+/g, "")))];
}

/** Emmascara un IBAN deixant país + últims 4 (mai sencer a logs). */
export function maskIban(iban: string): string {
  if (!iban) return "";
  return `${iban.slice(0, 2)}****${iban.slice(-4)}`;
}

/**
 * Llegeix la sessió i exigeix que estigui AUTHORIZED. Si no ho està, llança un
 * error que l'app pot interpretar com a "cal re-autoritzar" (details.needsReauth).
 */
export async function getAuthorizedSession(
  ctx: EbCtx,
  sessionId: string
): Promise<EbSession> {
  const session = await enableBankingFetch<EbSession>(
    `/sessions/${sessionId}`,
    { method: "GET", jwt: ctx.jwt, baseUrl: ctx.baseUrl }
  );
  if (session.status && session.status !== "AUTHORIZED") {
    throw new HttpsError(
      "failed-precondition",
      `La sessió bancària no està activa (${session.status}). Torna a connectar el banc.`,
      { needsReauth: true, status: session.status }
    );
  }
  return session;
}

/** Extreu els UID de compte de la sessió (amb fallbacks robustos). */
export function accountUidsOf(
  session: EbSession,
  storedAccounts: EbAccount[]
): string[] {
  let uids = (session.accounts ?? [])
    .map((a) => (typeof a === "string" ? a : (a as EbAccount)?.uid ?? ""))
    .filter((u): u is string => !!u);
  if (uids.length === 0) {
    uids = (session.accounts_data ?? [])
      .map((a) => a.uid ?? "")
      .filter(Boolean);
  }
  if (uids.length === 0) {
    uids = (storedAccounts ?? []).map((a) => a.uid ?? "").filter(Boolean);
  }
  return uids;
}

/** Detalls (amb IBAN) d'un compte per uid. */
export async function fetchAccountDetails(
  ctx: EbCtx,
  uid: string
): Promise<EbAccount> {
  const d = await enableBankingFetch<EbAccount>(`/accounts/${uid}/details`, {
    method: "GET",
    jwt: ctx.jwt,
    baseUrl: ctx.baseUrl,
  });
  return { ...d, uid: d.uid ?? uid };
}
