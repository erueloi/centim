import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

/**
 * Xifratge en repòs de la clau privada d'Enable Banking de cada grup.
 *
 * - AES-256-GCM, IV aleatori de 96 bits per a cada xifratge.
 * - El groupId és l'AAD: un text xifrat copiat a un altre grup no es pot
 *   desxifrar.
 * - La clau mestra ve d'un "keyring" (secret BANK_APP_MASTER_KEYRING):
 *     { "current": "v1", "keys": { "v1": "<32 bytes en base64>" } }
 *   Es xifra amb `current` i es desxifra amb la versió desada al document, així
 *   es pot rotar afegint "v2" sense trencar els documents antics.
 *
 * Res d'aquest mòdul escriu logs: ni la clau mestra ni el text en clar.
 */

const ALGORITHM = "aes-256-gcm";
const IV_BYTES = 12; // 96 bits, el recomanat per a GCM
const KEY_BYTES = 32;
const AUTH_TAG_BYTES = 16;

export interface EncryptedSecret {
  ciphertext: string; // base64
  iv: string; // base64
  authTag: string; // base64
  keyVersion: string;
}

export interface MasterKeyring {
  current: string;
  keys: Record<string, Buffer>;
}

/** Interpreta i valida el keyring. Mai inclou valors de clau als errors. */
export function parseKeyring(raw: string | undefined): MasterKeyring {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw ?? "");
  } catch {
    throw new Error("BANK_APP_MASTER_KEYRING no és un JSON vàlid.");
  }
  const data = parsed as { current?: unknown; keys?: unknown };
  if (typeof data.current !== "string" || !data.keys || typeof data.keys !== "object") {
    throw new Error("BANK_APP_MASTER_KEYRING ha de tenir `current` i `keys`.");
  }
  const keys: Record<string, Buffer> = {};
  for (const [version, value] of Object.entries(data.keys as Record<string, unknown>)) {
    const key = typeof value === "string" ? Buffer.from(value, "base64") : Buffer.alloc(0);
    if (key.length !== KEY_BYTES) {
      throw new Error(`La clau mestra "${version}" ha de tenir ${KEY_BYTES} bytes.`);
    }
    keys[version] = key;
  }
  if (!keys[data.current]) {
    throw new Error(`La versió actual "${data.current}" no és al keyring.`);
  }
  return { current: data.current, keys };
}

export function encryptSecret(
  plaintext: string,
  groupId: string,
  keyring: MasterKeyring
): EncryptedSecret {
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv(ALGORITHM, keyring.keys[keyring.current], iv);
  cipher.setAAD(Buffer.from(groupId, "utf8"));
  const ciphertext = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  return {
    ciphertext: ciphertext.toString("base64"),
    iv: iv.toString("base64"),
    authTag: cipher.getAuthTag().toString("base64"),
    keyVersion: keyring.current,
  };
}

/**
 * Desxifra. Falla si el text xifrat, l'IV o l'authTag s'han manipulat, si el
 * groupId (AAD) no és el del document o si la versió de clau no existeix.
 */
export function decryptSecret(
  secret: EncryptedSecret,
  groupId: string,
  keyring: MasterKeyring
): string {
  const key = keyring.keys[secret.keyVersion];
  if (!key) {
    throw new Error(`Versió de clau mestra desconeguda: ${secret.keyVersion}.`);
  }
  const iv = Buffer.from(secret.iv, "base64");
  if (iv.length !== IV_BYTES) throw new Error("IV no vàlid.");
  // GCM acceptaria etiquetes retallades (més fàcils de falsificar): exigim 128 bits.
  const authTag = Buffer.from(secret.authTag, "base64");
  if (authTag.length !== AUTH_TAG_BYTES) throw new Error("authTag no vàlid.");
  const decipher = createDecipheriv(ALGORITHM, key, iv, {
    authTagLength: AUTH_TAG_BYTES,
  });
  decipher.setAAD(Buffer.from(groupId, "utf8"));
  decipher.setAuthTag(authTag);
  return Buffer.concat([
    decipher.update(Buffer.from(secret.ciphertext, "base64")),
    decipher.final(),
  ]).toString("utf8");
}
