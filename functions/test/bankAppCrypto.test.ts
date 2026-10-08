import { randomBytes } from "node:crypto";
import { describe, expect, it } from "vitest";

import {
  decryptSecret,
  encryptSecret,
  parseKeyring,
} from "../src/bankAppCrypto.js";
import { generatePem } from "./helpers.js";

const key = () => randomBytes(32).toString("base64");
const keyring = parseKeyring(JSON.stringify({ current: "v1", keys: { v1: key() } }));
const pem = generatePem();

/** Canvia un bit d'un camp base64. */
function flipBit(base64: string, byte = 0): string {
  const buf = Buffer.from(base64, "base64");
  buf[byte] ^= 0x01;
  return buf.toString("base64");
}

describe("xifratge AES-256-GCM de la clau del grup", () => {
  it("xifrar i desxifrar recupera la clau exacta", () => {
    const secret = encryptSecret(pem, "gA", keyring);
    expect(decryptSecret(secret, "gA", keyring)).toBe(pem);
  });

  it("el text xifrat no conté la clau en clar", () => {
    const secret = encryptSecret(pem, "gA", keyring);
    expect(JSON.stringify(secret)).not.toContain("PRIVATE KEY");
    expect(Buffer.from(secret.ciphertext, "base64").toString("utf8")).not.toContain("PRIVATE KEY");
  });

  it("IV de 96 bits, diferent a cada xifratge de la mateixa clau", () => {
    const a = encryptSecret(pem, "gA", keyring);
    const b = encryptSecret(pem, "gA", keyring);
    expect(Buffer.from(a.iv, "base64")).toHaveLength(12);
    expect(a.iv).not.toBe(b.iv);
    expect(a.ciphertext).not.toBe(b.ciphertext);
  });

  it("desa la versió de la clau mestra", () => {
    expect(encryptSecret(pem, "gA", keyring).keyVersion).toBe("v1");
  });

  it("amb el groupId d'un altre grup (AAD) no es pot desxifrar", () => {
    const secret = encryptSecret(pem, "gA", keyring);
    expect(() => decryptSecret(secret, "gB", keyring)).toThrow();
  });

  it("un bit canviat al text xifrat, a l'IV o a l'authTag fa fallar el desxifratge", () => {
    const secret = encryptSecret(pem, "gA", keyring);
    expect(() => decryptSecret({ ...secret, ciphertext: flipBit(secret.ciphertext, 10) }, "gA", keyring)).toThrow();
    expect(() => decryptSecret({ ...secret, iv: flipBit(secret.iv) }, "gA", keyring)).toThrow();
    expect(() => decryptSecret({ ...secret, authTag: flipBit(secret.authTag) }, "gA", keyring)).toThrow();
  });

  it("no accepta un authTag retallat", () => {
    const secret = encryptSecret(pem, "gA", keyring);
    const truncated = Buffer.from(secret.authTag, "base64").subarray(0, 8).toString("base64");
    expect(() => decryptSecret({ ...secret, authTag: truncated }, "gA", keyring)).toThrow(/authTag/);
  });

  it("amb una altra clau mestra no es pot desxifrar", () => {
    const secret = encryptSecret(pem, "gA", keyring);
    const other = parseKeyring(JSON.stringify({ current: "v1", keys: { v1: key() } }));
    expect(() => decryptSecret(secret, "gA", other)).toThrow();
  });

  it("rotació: es xifra amb la versió actual i es continuen llegint les antigues", () => {
    const v1 = key();
    const old = parseKeyring(JSON.stringify({ current: "v1", keys: { v1 } }));
    const rotated = parseKeyring(JSON.stringify({ current: "v2", keys: { v1, v2: key() } }));
    const before = encryptSecret(pem, "gA", old);
    const after = encryptSecret(pem, "gA", rotated);
    expect(after.keyVersion).toBe("v2");
    expect(decryptSecret(before, "gA", rotated)).toBe(pem);
    expect(decryptSecret(after, "gA", rotated)).toBe(pem);
  });

  it("una versió de clau desconeguda dona error", () => {
    const secret = { ...encryptSecret(pem, "gA", keyring), keyVersion: "v9" };
    expect(() => decryptSecret(secret, "gA", keyring)).toThrow(/v9/);
  });
});

describe("keyring", () => {
  it("rebutja JSON invàlid, claus de mida incorrecta i una versió actual inexistent", () => {
    expect(() => parseKeyring("no-json")).toThrow();
    expect(() => parseKeyring(JSON.stringify({ current: "v1", keys: { v1: "curta" } }))).toThrow(/32 bytes/);
    expect(() => parseKeyring(JSON.stringify({ current: "v2", keys: { v1: key() } }))).toThrow(/v2/);
  });

  it("els errors no contenen el valor de cap clau", () => {
    const short = Buffer.from("massa-curta").toString("base64");
    try {
      parseKeyring(JSON.stringify({ current: "v1", keys: { v1: short } }));
    } catch (error) {
      expect(String(error)).not.toContain(short);
    }
  });
});
