// Prova el camí COMPLET: crida la callable desplegada startBankAuth amb un ID
// token de Firebase (requereix haver desplegat i carregat els secrets).
//
// Ús (des de functions/):
//   EB_ID_TOKEN=<idToken>  node scripts/call_start_auth.mjs
//   # opcional: EB_PROJECT=centim-162bd  EB_REGION=europe-west1  EB_FN=startBankAuth
//
// Com obtenir un ID token d'un usuari de test (email/password), amb la Web API
// key del projecte (Firebase console → Project settings → Web API Key):
//   curl -s "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=<WEB_API_KEY>" \
//     -H "Content-Type: application/json" \
//     -d '{"email":"test@exemple.com","password":"...","returnSecureToken":true}' \
//     | jq -r .idToken

import { getIdToken } from "./ebToken.mjs";

const project = process.env.EB_PROJECT ?? "centim-162bd";
const region = process.env.EB_REGION ?? "europe-west1";
const fn = process.env.EB_FN ?? "startBankAuth";
const idToken = await getIdToken();

const url = `https://${region}-${project}.cloudfunctions.net/${fn}`;

const res = await fetch(url, {
  method: "POST",
  headers: {
    Authorization: `Bearer ${idToken}`,
    "Content-Type": "application/json",
  },
  // Les callable v2 esperen el payload dins de { data: ... }.
  body: JSON.stringify({ data: {} }),
});

const text = await res.text();
if (!res.ok) {
  console.error(`✗ ${fn} ha retornat ${res.status}`);
  console.error(text.slice(0, 800));
  process.exit(1);
}

// La resposta callable ve dins de { result: ... }.
const body = JSON.parse(text);
const result = body.result ?? body;
console.log("✓ " + fn + " OK");
console.log("authUrl:     " + result.authUrl);
console.log("aspspName:   " + result.aspspName);
console.log("validUntil:  " + result.validUntil);
console.log("authMethods: " + JSON.stringify(result.authMethods, null, 2));
