// Prova de només-lectura: crida la callable temporal probeAccountData i imprimeix
// saldo + últims moviments del compte amb l'IBAN indicat (per defecte acaba en 00161717).
//
// Ús (des de functions/):
//   $env:EB_ID_TOKEN = (node scripts/get_id_token.mjs)
//   node scripts/call_probe.mjs
//   # opcional: $env:EB_IBAN_SUFFIX = "00161717"

import { getIdToken } from "./ebToken.mjs";

const project = process.env.EB_PROJECT ?? "centim-162bd";
const region = process.env.EB_REGION ?? "europe-west1";
const ibanSuffix = process.env.EB_IBAN_SUFFIX ?? "00161717";
const listOnly = !!process.env.EB_LIST; // EB_LIST=1 → només llistar comptes
const idToken = await getIdToken();

const url = `https://${region}-${project}.cloudfunctions.net/probeAccountData`;
const res = await fetch(url, {
  method: "POST",
  headers: { Authorization: `Bearer ${idToken}`, "Content-Type": "application/json" },
  body: JSON.stringify({ data: listOnly ? { list: true } : { ibanSuffix } }),
});

const text = await res.text();
if (!res.ok) {
  console.error(`✗ probeAccountData ${res.status}`);
  console.error(text.slice(0, 800));
  process.exit(1);
}

const r = JSON.parse(text).result ?? {};

if (r.mode === "list") {
  console.log("✓ Comptes a la sessió (entorn " + r.env + "):");
  for (const a of r.accounts ?? []) {
    console.log(`  - ${a.name ?? "(sense nom)"}  uid:${a.uidMasked}  IBANs:${JSON.stringify(a.ibansMasked)}`);
  }
  process.exit(0);
}

console.log("✓ Probe OK");
console.log("entorn:      " + r.env);
console.log("IBAN:        " + r.ibanMasked);
console.log("\nSaldos:");
for (const b of r.balances ?? []) {
  console.log(`  [${b.type ?? "?"}] ${b.name ?? ""}: ${b.amount} ${b.currency}`);
}
console.log(`\nMoviments: ${r.txCount} (${r.dateRange?.from} → ${r.dateRange?.to})`);
for (const t of r.transactions ?? []) {
  const sign = t.direction === "in" ? "+" : "-";
  console.log(`  ${t.bookingDate}  ${sign}${t.amount} ${t.currency}  ref:${t.ref}`);
}
