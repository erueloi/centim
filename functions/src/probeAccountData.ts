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
  enableBankingFetch,
  requireUid,
} from "./enableBanking.js";

// ============================================================================
// PROBE TEMPORAL — NO és un endpoint de debug permanent.
// Objectiu: confirmar la cadena sencera clau prod → JWT → CaixaBank → dades.
// Llegeix NOMÉS (saldo + últims moviments) del compte amb l'IBAN indicat.
// Per treure-ho: esborra aquest fitxer i la línia d'export a index.ts.
// ============================================================================

const DEFAULT_IBAN_SUFFIX = "00161717";
const DEFAULT_TX_LOOKBACK_DAYS = 60;
const DEFAULT_MAX_TX = 10;

interface EbAccountId {
  identification?: string;
  scheme_name?: string;
}
interface EbAccount {
  uid?: string;
  account_id?: { iban?: string };
  all_account_ids?: EbAccountId[];
  name?: string;
}
interface EbSession {
  status?: string;
  /** GET /sessions/{id}: llista d'UID (strings), no objectes. */
  accounts?: unknown[];
  /** GET /sessions/{id}: dades reals dels comptes (objectes amb IBAN). */
  accounts_data?: EbAccount[];
}
interface EbBalance {
  balance_amount?: { amount?: string; currency?: string };
  balance_type?: string;
  name?: string;
}
interface EbBalancesResponse {
  balances?: EbBalance[];
}
interface EbTransaction {
  transaction_amount?: { amount?: string; currency?: string };
  credit_debit_indicator?: string;
  booking_date?: string;
  value_date?: string;
  entry_reference?: string;
}
interface EbTransactionsResponse {
  transactions?: EbTransaction[];
}

/** Emmascara un IBAN deixant només país + últims 4 (mai sencer a logs/retorn). */
function maskIban(iban: string): string {
  if (!iban) return "";
  const tail = iban.slice(-4);
  const head = iban.slice(0, 2);
  return `${head}****${tail}`;
}

/** Emmascara un identificador llarg deixant els últims 4. */
function maskId(id: string): string {
  if (!id) return "";
  return id.length <= 4 ? "****" : `****${id.slice(-4)}`;
}

/** Recull tots els IBAN candidats d'un compte. */
function ibansOf(acc: EbAccount): string[] {
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
  return out;
}

export const probeAccountData = onCall(
  {
    region: REGION,
    secrets: ALL_EB_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);
    const listOnly = request.data?.list === true;
    const ibanSuffix = (
      (request.data?.ibanSuffix as string) ?? DEFAULT_IBAN_SUFFIX
    ).trim();
    const maxTx = (request.data?.maxTx as number) ?? DEFAULT_MAX_TX;

    const creds = resolveEbCredentials();
    const slug = aspspSlug(ASPSP_NAME.value());

    // 1. Recuperar la sessió desada per aquest usuari.
    const db = getFirestore();
    const snap = await db.doc(bankConnectionDoc(uid, slug)).get();
    const sessionId = snap.get("sessionId") as string | undefined;
    if (!sessionId) {
      throw new HttpsError(
        "failed-precondition",
        "No hi ha cap sessió bancària. Connecta el banc (SCA) primer."
      );
    }

    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);

    // 2. Rellegir la sessió (l'account uid només és vàlid si està AUTHORIZED).
    const session = await enableBankingFetch<EbSession>(
      `/sessions/${sessionId}`,
      { method: "GET", jwt, baseUrl: creds.baseUrl }
    );
    if (session.status && session.status !== "AUTHORIZED") {
      throw new HttpsError(
        "failed-precondition",
        `La sessió no està activa (estat: ${session.status}). Torna a connectar.`
      );
    }

    // Els UID canònics venen a session.accounts (strings). Ni accounts ni
    // accounts_data porten l'IBAN de manera fiable: cal l'endpoint dedicat
    // /accounts/{uid}/details per obtenir-lo.
    const uids: string[] = (session.accounts ?? [])
      .map((a) => (typeof a === "string" ? a : (a as EbAccount)?.uid ?? ""))
      .filter((u): u is string => !!u);
    // Fallbacks per si la forma de la resposta canviés.
    if (uids.length === 0) {
      for (const a of session.accounts_data ?? []) if (a.uid) uids.push(a.uid);
    }
    if (uids.length === 0) {
      for (const a of (snap.get("accounts") as EbAccount[] | undefined) ?? []) {
        if (a.uid) uids.push(a.uid);
      }
    }

    // Detalls (amb IBAN) de cada compte.
    const details: EbAccount[] = [];
    for (const u of uids) {
      const d = await enableBankingFetch<EbAccount>(`/accounts/${u}/details`, {
        method: "GET",
        jwt,
        baseUrl: creds.baseUrl,
      });
      details.push({ ...d, uid: d.uid ?? u });
    }

    // Mode llistar: retorna tots els comptes amb IBAN emmascarat per triar suffix.
    if (listOnly) {
      const listed = details.map((a) => ({
        name: a.name ?? null,
        uidMasked: maskId(a.uid ?? ""),
        ibansMasked: ibansOf(a).map(maskIban),
      }));
      logger.info("Probe list OK", {
        uid,
        env: creds.env,
        accountCount: details.length,
      });
      return { env: creds.env, mode: "list", accounts: listed };
    }

    // 3. Resoldre IBAN (acaba en <suffix>) → account uid.
    const target = details.find((a) =>
      ibansOf(a).some((ib) => ib.replace(/\s+/g, "").endsWith(ibanSuffix))
    );
    if (!target?.uid) {
      logger.warn("Compte objectiu no trobat a la sessió", {
        uid,
        env: creds.env,
        accountCount: details.length,
        // Només suffixos emmascarats, mai IBAN sencer.
        available: details.flatMap((a) => ibansOf(a).map(maskIban)),
      });
      throw new HttpsError(
        "not-found",
        `Cap compte amb IBAN acabat en ${ibanSuffix} a la sessió.`
      );
    }

    const accountUid = target.uid;
    const targetIban = ibansOf(target)[0] ?? "";

    // 4. Saldo.
    const balancesResp = await enableBankingFetch<EbBalancesResponse>(
      `/accounts/${accountUid}/balances`,
      { method: "GET", jwt, baseUrl: creds.baseUrl }
    );
    const balances = (balancesResp.balances ?? []).map((b) => ({
      type: b.balance_type ?? null,
      name: b.name ?? null,
      amount: b.balance_amount?.amount ?? null,
      currency: b.balance_amount?.currency ?? null,
    }));

    // 5. Últims moviments (finestra recent) → ordenar desc i tallar a maxTx.
    const from = new Date(
      Date.now() - DEFAULT_TX_LOOKBACK_DAYS * 24 * 60 * 60 * 1000
    )
      .toISOString()
      .slice(0, 10);
    const txResp = await enableBankingFetch<EbTransactionsResponse>(
      `/accounts/${accountUid}/transactions`,
      { method: "GET", jwt, baseUrl: creds.baseUrl, query: { date_from: from } }
    );
    const allTx = txResp.transactions ?? [];
    const sorted = [...allTx].sort((a, b) =>
      (b.booking_date ?? "").localeCompare(a.booking_date ?? "")
    );
    const picked = sorted.slice(0, maxTx);

    const transactions = picked.map((t) => ({
      bookingDate: t.booking_date ?? null,
      valueDate: t.value_date ?? null,
      amount: t.transaction_amount?.amount ?? null,
      currency: t.transaction_amount?.currency ?? null,
      direction: t.credit_debit_indicator === "CRDT" ? "in" : "out",
      ref: maskId(t.entry_reference ?? ""),
    }));

    const dates = picked
      .map((t) => t.booking_date)
      .filter((d): d is string => !!d)
      .sort();

    // LOG: només metadades no sensibles (mai IBAN sencer ni imports).
    logger.info("Probe de compte OK", {
      uid,
      env: creds.env,
      ibanMasked: maskIban(targetIban),
      accountUid: maskId(accountUid),
      balanceCount: balances.length,
      txCount: transactions.length,
      dateFrom: dates[0] ?? null,
      dateTo: dates[dates.length - 1] ?? null,
    });

    // RETORN: al propi usuari (dades seves). IBAN emmascarat també aquí.
    return {
      env: creds.env,
      ibanMasked: maskIban(targetIban),
      balances,
      txCount: transactions.length,
      dateRange: { from: dates[0] ?? null, to: dates[dates.length - 1] ?? null },
      transactions,
    };
  }
);
