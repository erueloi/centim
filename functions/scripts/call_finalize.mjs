// Tanca la sessió: crida la callable finalizeBankSession amb el code+state
// capturats a la pàgina /bank-callback després de la SCA.
//
// Ús (des de functions/):
//   $env:EB_ID_TOKEN = (node scripts/get_id_token.mjs)   # o un token que ja tinguis
//   $env:EB_CODE  = "<code de la URL de callback>"
//   $env:EB_STATE = "<state de la URL de callback>"
//   node scripts/call_finalize.mjs

import { getIdToken } from "./ebToken.mjs";

const project = process.env.EB_PROJECT ?? "centim-162bd";
const region = process.env.EB_REGION ?? "europe-west1";
const code = process.env.EB_CODE;
const state = process.env.EB_STATE;

if (!code || !state) {
  console.error("✗ Falten EB_CODE i/o EB_STATE.");
  process.exit(1);
}
const idToken = await getIdToken();

const url = `https://${region}-${project}.cloudfunctions.net/finalizeBankSession`;
const res = await fetch(url, {
  method: "POST",
  headers: { Authorization: `Bearer ${idToken}`, "Content-Type": "application/json" },
  body: JSON.stringify({ data: { code, state } }),
});

const text = await res.text();
if (!res.ok) {
  console.error(`✗ finalizeBankSession ${res.status}`);
  console.error(text.slice(0, 800));
  process.exit(1);
}
const result = JSON.parse(text).result ?? {};
console.log("✓ Sessió establerta");
console.log("status:      " + result.status);
console.log("accountCount:" + result.accountCount);
console.log("validUntil:  " + result.validUntil);
