import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  ASPSP_NAME,
  ASPSP_COUNTRY,
  aspspSlug,
  bankConnectionDoc,
  ALL_EB_SECRETS,
  resolveEbCredentials,
} from "./config.js";
import { buildPsuHeaders } from "./psuHeaders.js";
import {
  buildEnableBankingJwt,
  enableBankingFetch,
  requireUid,
} from "./enableBanking.js";
import {
  EbAccount,
  ibansOf,
  maskIban,
  accountKeyOf,
} from "./ebAccounts.js";

// Finestra de dates per defecte i límits de paginació.
const DEFAULT_LOOKBACK_DAYS = 90;
const MAX_PAGES = 20;

interface EbTransaction {
  transaction_amount?: { amount?: string; currency?: string };
  credit_debit_indicator?: string;
  booking_date?: string;
  value_date?: string;
  transaction_date?: string;
  entry_reference?: string;
  remittance_information?: string[];
  creditor?: { name?: string };
  debtor?: { name?: string };
  bank_transaction_code?: {
    description?: string;
    code?: string;
    sub_code?: string;
  };
  merchant_category_code?: string;
}
interface EbTransactionsResponse {
  transactions?: EbTransaction[];
  continuation_key?: string;
}

/** Moviment normalitzat al shape que consumirà l'app (ImportedTransaction). */
interface NormalizedTx {
  bankTxId: string | null;
  date: string | null; // YYYY-MM-DD
  amount: number; // amb signe: + ingrés, - despesa
  currency: string | null;
  concept: string;
  isIncome: boolean;
  mcc: string | null;
}

/** Construeix el concepte: nom de la contrapart + informació de remesa. */
function buildConcept(t: EbTransaction): string {
  const isCredit = t.credit_debit_indicator === "CRDT";
  // En un ingrés, la contrapart és el debtor; en una despesa, el creditor.
  const counterparty = isCredit ? t.debtor?.name : t.creditor?.name;
  const parts: string[] = [];
  if (counterparty && counterparty.trim()) parts.push(counterparty.trim());
  for (const r of t.remittance_information ?? []) {
    if (r && r.trim()) parts.push(r.trim());
  }
  let concept = parts.join(" — ").replace(/\s+/g, " ").trim();
  if (!concept) concept = t.bank_transaction_code?.description?.trim() ?? "Moviment";
  return concept;
}

function normalizeTx(t: EbTransaction): NormalizedTx | null {
  const amtStr = t.transaction_amount?.amount;
  if (amtStr == null) return null;
  const raw = Number(amtStr);
  if (!Number.isFinite(raw)) return null;
  const isCredit = t.credit_debit_indicator === "CRDT";
  const amount = isCredit ? Math.abs(raw) : -Math.abs(raw);
  return {
    bankTxId: t.entry_reference ?? null,
    date: t.booking_date ?? t.value_date ?? t.transaction_date ?? null,
    amount,
    currency: t.transaction_amount?.currency ?? null,
    concept: buildConcept(t),
    isIncome: isCredit,
    mcc: t.merchant_category_code ?? null,
  };
}

interface EbCtx {
  jwt: string;
  baseUrl: string;
  /** Capçaleres PSU-* (accés amb el client present). */
  psuHeaders?: Record<string, string>;
}

/** Recull tots els moviments d'un compte seguint la paginació (continuation_key). */
async function fetchAllTransactions(
  ctx: EbCtx,
  uid: string,
  dateFrom: string,
  dateTo?: string
): Promise<EbTransaction[]> {
  const all: EbTransaction[] = [];
  let continuationKey: string | undefined;
  for (let page = 0; page < MAX_PAGES; page++) {
    const query: Record<string, string> = { date_from: dateFrom };
    if (dateTo) query.date_to = dateTo;
    if (continuationKey) query.continuation_key = continuationKey;
    const resp = await enableBankingFetch<EbTransactionsResponse>(
      `/accounts/${uid}/transactions`,
      {
        method: "GET",
        jwt: ctx.jwt,
        baseUrl: ctx.baseUrl,
        query,
        extraHeaders: ctx.psuHeaders,
      }
    );
    for (const t of resp.transactions ?? []) all.push(t);
    continuationKey = resp.continuation_key;
    if (!continuationKey) break;
  }
  return all;
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

/**
 * Fase 2 — retorna moviments i saldos NORMALITZATS dels comptes linked, per
 * alimentar el mateix pipeline de revisió/dedup/categorització que l'Excel.
 * NO escriu res a Firestore: l'app processa i confirma.
 */
export const fetchBankTransactions = onCall(
  {
    region: REGION,
    secrets: ALL_EB_SECRETS,
  },
  async (request) => {
    const uid = requireUid(request);

    // Peticions per compte: [{ key, dateFrom? }]. Si no se'n passen, es baixen
    // tots els comptes amb la finestra per defecte (comportament legacy).
    const perAccount =
      (request.data?.accounts as { key: string; dateFrom?: string }[] | undefined) ??
      null;
    const requestedByKey = new Map<string, string | undefined>();
    if (perAccount) {
      for (const a of perAccount) requestedByKey.set(a.key, a.dateFrom);
    }

    const ibanSuffix = (request.data?.ibanSuffix as string | undefined)?.trim();
    const defaultDateFrom =
      (request.data?.dateFrom as string | undefined) ??
      isoDate(new Date(Date.now() - DEFAULT_LOOKBACK_DAYS * 86400 * 1000));
    const dateTo = request.data?.dateTo as string | undefined;

    const creds = resolveEbCredentials();
    const slug = aspspSlug(ASPSP_NAME.value());

    const db = getFirestore();
    const docRef = db.doc(bankConnectionDoc(uid, slug));
    const snap = await docRef.get();
    const sessionId = snap.get("sessionId") as string | undefined;
    if (!sessionId) {
      throw new HttpsError(
        "failed-precondition",
        "No hi ha cap sessió bancària. Connecta el banc primer.",
        { needsReauth: true }
      );
    }

    const jwt = await buildEnableBankingJwt(creds.appId, creds.pem);

    // Capçaleres PSU: marquen la consulta com a feta AMB EL CLIENT PRESENT
    // (l'usuari acaba de prémer "Sincronitza"), que és el que evita la quota
    // d'accés desatès (~4/dia). Cal saber quines exigeix el banc: es desen a
    // startBankAuth, i per a connexions anteriors les resolem un cop aquí.
    let requiredPsuHeaders = snap.get("requiredPsuHeaders") as
      | string[]
      | undefined;
    if (requiredPsuHeaders === undefined) {
      try {
        const catalog = await enableBankingFetch<{
          aspsps?: { name: string; required_psu_headers?: string[] }[];
        }>("/aspsps", {
          method: "GET",
          jwt,
          baseUrl: creds.baseUrl,
          query: { country: ASPSP_COUNTRY.value() },
        });
        const target = ASPSP_NAME.value().toLowerCase();
        requiredPsuHeaders =
          (catalog.aspsps ?? []).find(
            (a) => a.name.toLowerCase() === target
          )?.required_psu_headers ?? [];
        await docRef.set({ requiredPsuHeaders }, { merge: true });
      } catch {
        requiredPsuHeaders = [];
      }
    }

    const psuHeaders = buildPsuHeaders(request.rawRequest, requiredPsuHeaders);
    const ctx: EbCtx = { jwt, baseUrl: creds.baseUrl, psuHeaders };

    // La PSD2 limita les consultes AIS sense el client present (~4 per compte i
    // dia). Per no malgastar-ne cap: comprovem la caducitat amb el validUntil
    // desat (sense cridar GET /sessions) i les metadades dels comptes surten de
    // la caché escrita a finalize. Si la sessió s'hagués revocat, la crida de
    // moviments retornarà 401 i el propagarem com a "cal reconnectar".
    const validUntilStr = snap.get("validUntil") as string | undefined;
    if (validUntilStr) {
      const validUntil = new Date(validUntilStr);
      if (!Number.isNaN(validUntil.getTime()) && validUntil < new Date()) {
        throw new HttpsError(
          "failed-precondition",
          "El consentiment del banc ha caducat. Torna a connectar el banc.",
          { needsReauth: true }
        );
      }
    }

    const storedAccounts =
      (snap.get("accounts") as EbAccount[] | undefined) ?? [];

    const accountsOut = [];
    let txTotal = 0;

    for (const acc of storedAccounts) {
      const accUid = acc.uid;
      if (!accUid) continue;
      const key = accountKeyOf(acc);
      const ibans = ibansOf(acc);

      // Filtres d'inclusió: per petició explícita (perAccount) o per ibanSuffix.
      if (perAccount && !requestedByKey.has(key)) continue;
      if (ibanSuffix && !ibans.some((ib) => ib.endsWith(ibanSuffix))) continue;

      const accDateFrom = perAccount
        ? requestedByKey.get(key) ?? defaultDateFrom
        : defaultDateFrom;

      // El banc (Redsys) limita l'històric recuperable. Si rebutja el dateFrom,
      // no fem petar tot el sync: marquem un avís i retornem el compte sense
      // moviments perquè l'usuari en pugui triar un de més recent.
      let transactions: NormalizedTx[] = [];
      let warning: string | null = null;
      try {
        const rawTx = await fetchAllTransactions(
          ctx,
          accUid,
          accDateFrom,
          dateTo
        );
        transactions = rawTx
          .map(normalizeTx)
          .filter((t): t is NormalizedTx => t !== null);
      } catch (e) {
        // Els errors que l'usuari ha d'entendre tal qual (límit de consultes,
        // autorització revocada) NO s'amaguen darrere d'un avís: es propaguen.
        if (
          e instanceof HttpsError &&
          (e.code === "resource-exhausted" || e.code === "permission-denied")
        ) {
          throw e;
        }
        const status =
          e instanceof HttpsError &&
          e.details &&
          typeof e.details === "object" &&
          "status" in e.details
            ? (e.details as { status?: number }).status
            : undefined;
        // 400/422 solen indicar rang de dates no admès; la resta, error genèric.
        warning =
          status === 400 || status === 422
            ? "El banc no permet recuperar moviments des d'aquesta data. Prova una data d'inici més recent."
            : `No s'han pogut recuperar els moviments d'aquest compte${
                status != null ? ` (error ${status})` : ""
              }.`;
        logger.warn("Error baixant moviments d'un compte", {
          uid,
          env: creds.env,
          accountKey: key,
          status: status ?? null,
          dateFrom: accDateFrom,
        });
      }
      txTotal += transactions.length;

      accountsOut.push({
        accountKey: key,
        ibanMasked: maskIban(ibans[0] ?? ""),
        name: acc.name ?? null,
        currency: acc.currency ?? null,
        dateFrom: accDateFrom,
        transactionCount: transactions.length,
        transactions,
        warning,
      });
    }

    // LOG: només metadades (mai IBAN sencer, imports ni conceptes).
    logger.info("fetchBankTransactions OK", {
      uid,
      env: creds.env,
      accountCount: accountsOut.length,
      txTotal,
      dateTo: dateTo ?? null,
      // Només els NOMS de les capçaleres PSU: mai la IP (dada personal).
      psuHeadersSent: Object.keys(psuHeaders),
      requiredPsuHeaders,
    });

    return {
      env: creds.env,
      dateTo: dateTo ?? null,
      accounts: accountsOut,
    };
  }
);
