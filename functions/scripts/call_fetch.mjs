// Prova de fetchBankTransactions: mostra saldos i moviments normalitzats
// (data, import amb signe, i CONCEPTE) per verificar que la descripció arriba.
//
// Ús (des de functions/):
//   $env:EB_ID_TOKEN = (node scripts/get_id_token.mjs)
//   node scripts/call_fetch.mjs
//   # opcional: $env:EB_IBAN_SUFFIX="<ultims digits IBAN>"  $env:EB_DATE_FROM="2026-01-01"

import { getIdToken } from "./ebToken.mjs";

const project = process.env.EB_PROJECT ?? "centim-162bd";
const region = process.env.EB_REGION ?? "europe-west1";
const idToken = await getIdToken();

const data = {};
if (process.env.EB_IBAN_SUFFIX) data.ibanSuffix = process.env.EB_IBAN_SUFFIX;
if (process.env.EB_DATE_FROM) data.dateFrom = process.env.EB_DATE_FROM;
if (process.env.EB_DATE_TO) data.dateTo = process.env.EB_DATE_TO;

const url = `https://${region}-${project}.cloudfunctions.net/fetchBankTransactions`;
const res = await fetch(url, {
  method: "POST",
  headers: { Authorization: `Bearer ${idToken}`, "Content-Type": "application/json" },
  body: JSON.stringify({ data }),
});

const text = await res.text();
if (!res.ok) {
  console.error(`✗ fetchBankTransactions ${res.status}`);
  console.error(text.slice(0, 900));
  process.exit(1);
}

const r = JSON.parse(text).result ?? {};
console.log(`✓ fetch OK (entorn ${r.env}, des de ${r.dateFrom})`);
for (const acc of r.accounts ?? []) {
  console.log(`\n=== ${acc.name ?? "(compte)"}  ${acc.ibanMasked} ===`);
  for (const b of acc.balances ?? []) {
    console.log(`  saldo [${b.type}] ${b.name}: ${b.amount} ${b.currency}`);
  }
  console.log(`  moviments: ${acc.transactionCount}`);
  for (const t of (acc.transactions ?? []).slice(0, 12)) {
    const sign = t.amount >= 0 ? "+" : "";
    console.log(`   ${t.date}  ${sign}${t.amount} ${t.currency}  | ${t.concept}`);
  }
}
