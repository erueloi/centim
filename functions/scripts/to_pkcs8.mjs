// Normalitza una clau privada RSA a PEM PKCS#8 (el format que necessita jose).
// Accepta tant PKCS#1 (BEGIN RSA PRIVATE KEY) com PKCS#8 (BEGIN PRIVATE KEY) i
// escriu sempre PKCS#8. Si la clau no és vàlida, avisa.
//
// Ús (des de functions/):
//   node scripts/to_pkcs8.mjs "C:\git\b99c325f-...-.pem"
//   # opcional 2n argument = ruta de sortida (per defecte: <input>_pkcs8.pem)

import { readFileSync, writeFileSync } from "node:fs";
import { createPrivateKey } from "node:crypto";

const input = process.argv[2];
if (!input) {
  console.error('✗ Falta la ruta. Ex: node scripts/to_pkcs8.mjs "C:\\git\\clau.pem"');
  process.exit(1);
}
const output = process.argv[3] ?? input.replace(/\.pem$/i, "") + "_pkcs8.pem";

let raw;
try {
  raw = readFileSync(input, "utf8");
} catch (e) {
  console.error("✗ No s'ha pogut llegir el fitxer: " + e.message);
  process.exit(1);
}

let keyObj;
try {
  keyObj = createPrivateKey(raw);
} catch (e) {
  console.error("✗ La clau no és vàlida o no s'ha pogut llegir: " + e.message);
  process.exit(1);
}

const pkcs8 = keyObj.export({ type: "pkcs8", format: "pem" });
writeFileSync(output, pkcs8, "utf8");

console.log("✓ Clau normalitzada a PKCS#8");
console.log("  Entrada: " + input);
console.log("  Sortida: " + output);
console.log("  Primera línia: " + String(pkcs8).split(/\r?\n/)[0]);
