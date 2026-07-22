// Test directe de Enable Banking: signa el JWT i crida GET /aspsps.
// NO desplega res, NO usa Firebase Auth ni Secret Manager. Serveix per confirmar
// ràpidament que CaixaBank surt al Sandbox i llegir-ne auth_methods i validesa.
//
// Ús (des de la carpeta functions/, on hi ha node_modules amb `jose`):
//   EB_APP_ID=<uuid-app>  EB_PEM_PATH=/ruta/segura/fora/del/repo/clau_pkcs8.pem  \
//     node scripts/test_aspsps.mjs
//
// Alternativa passant el PEM inline (compte amb l'historial de shell):
//   EB_APP_ID=<uuid>  EB_PEM="$(cat clau_pkcs8.pem)"  node scripts/test_aspsps.mjs
//
// La clau .pem ha de ser PKCS#8 (-----BEGIN PRIVATE KEY-----). Si la teva és
// PKCS#1 (BEGIN RSA PRIVATE KEY):
//   openssl pkcs8 -topk8 -nocrypt -in clau.pem -out clau_pkcs8.pem

import { readFileSync } from "node:fs";
import { importPKCS8, SignJWT } from "jose";

const BASE = "https://api.enablebanking.com";
const COUNTRY = process.env.EB_COUNTRY ?? "ES";
const NAME_MATCH = new RegExp(process.env.EB_NAME_MATCH ?? "caixa", "i");

function readConfig() {
  const appId = process.env.EB_APP_ID;
  if (!appId) fail("Falta EB_APP_ID (UUID de l'aplicació).");

  let pem = process.env.EB_PEM;
  if (!pem && process.env.EB_PEM_PATH) {
    pem = readFileSync(process.env.EB_PEM_PATH, "utf8");
  }
  if (!pem) fail("Falta la clau: posa EB_PEM_PATH (recomanat) o EB_PEM.");
  if (pem.includes("BEGIN RSA PRIVATE KEY")) {
    fail(
      "La clau és PKCS#1. Converteix-la a PKCS#8:\n" +
        "  openssl pkcs8 -topk8 -nocrypt -in clau.pem -out clau_pkcs8.pem"
    );
  }
  return { appId, pem };
}

function fail(msg) {
  console.error("✗ " + msg);
  process.exit(1);
}

async function buildJwt(appId, pem) {
  const key = await importPKCS8(pem, "RS256");
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({})
    .setProtectedHeader({ alg: "RS256", kid: appId, typ: "JWT" })
    .setIssuer("enablebanking.com")
    .setAudience("api.enablebanking.com")
    .setIssuedAt(now)
    .setExpirationTime(now + 300)
    .sign(key);
}

async function main() {
  const { appId, pem } = readConfig();
  const jwt = await buildJwt(appId, pem);

  const url = new URL(BASE + "/aspsps");
  url.searchParams.set("country", COUNTRY);

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${jwt}`, Accept: "application/json" },
  });

  const text = await res.text();
  if (!res.ok) {
    console.error(`✗ /aspsps ha retornat ${res.status}`);
    console.error(text.slice(0, 500));
    process.exit(1);
  }

  const data = JSON.parse(text);
  const all = data.aspsps ?? [];
  console.log(`✓ /aspsps OK — ${all.length} bancs a ${COUNTRY}`);

  const matches = all.filter(
    (a) => a.country === COUNTRY && NAME_MATCH.test(a.name)
  );

  if (matches.length === 0) {
    console.error(`✗ Cap banc coincideix amb /${NAME_MATCH.source}/i a ${COUNTRY}.`);
    console.error(
      "Noms disponibles: " + all.map((a) => a.name).sort().join(", ")
    );
    process.exit(1);
  }

  for (const a of matches) {
    const secs = a.maximum_consent_validity;
    const days = typeof secs === "number" ? (secs / 86400).toFixed(1) : "?";
    console.log("\n─────────────────────────────");
    console.log(`Banc:            ${a.name} (${a.country})`);
    console.log(`Validesa màx.:   ${secs ?? "?"} s  (~${days} dies)`);
    console.log(`psu_types:       ${JSON.stringify(a.psu_types ?? [])}`);
    console.log(`auth_methods:    ${JSON.stringify(a.auth_methods ?? [], null, 2)}`);
    if (a.sandbox !== undefined) console.log(`sandbox:         ${a.sandbox}`);
  }
}

main().catch((e) => fail(e.message ?? String(e)));
