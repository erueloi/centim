/**
 * FASE 0: només els grups de BANK_ALLOWED_GROUP_IDS poden fer servir la
 * connexió bancària. S'executa amb `npm run test:rules` (emulador de Firestore,
 * projecte fictici `demo-centim`): cap crida surt cap a Enable Banking.
 *
 * Personatges:
 *  - alice:   membre del grup permès (gAllowed)
 *  - mallory: membre d'un grup no permès (gOther)
 *  - eve:     apunta el seu currentGroupId a gAllowed sense ser-ne membre
 *  - nobody:  sense grup
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

import {
  BANK_NOT_ENABLED,
  parseAllowedGroupIds,
  requireBankAccess,
} from "../src/bankConnections.js";
import { startBankAuth } from "../src/startBankAuth.js";
import { finalizeBankSession } from "../src/finalizeBankSession.js";
import { fetchBankTransactions } from "../src/fetchBankTransactions.js";
import { listBankAccounts } from "../src/listBankAccounts.js";
import { inspectBankSessionAccounts } from "../src/inspectBankSessionAccounts.js";
import { updateBankAccountConfig } from "../src/updateBankAccountConfig.js";

const PROJECT_ID = "demo-centim";

function db() {
  if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
  return getFirestore();
}

/** Petició callable mínima, com la que construeix firebase-functions. */
function callAs(uid: string, data: Record<string, unknown> = {}) {
  return {
    data,
    auth: { uid, token: { uid } },
    rawRequest: { headers: {}, ip: "127.0.0.1" },
    acceptsStreaming: false,
  } as unknown as CallableRequest;
}

// Mateixes dades que enviaria l'app per a cada Function.
const FUNCTIONS = [
  ["startBankAuth", startBankAuth, {}],
  ["finalizeBankSession", finalizeBankSession, { code: "c", state: "s" }],
  ["fetchBankTransactions", fetchBankTransactions, {}],
  ["listBankAccounts", listBankAccounts, {}],
  ["inspectBankSessionAccounts", inspectBankSessionAccounts, { connectionId: "caixabank" }],
  ["updateBankAccountConfig", updateBankAccountConfig, { accountKey: "k", sync: true }],
] as const;

let fetchSpy: ReturnType<typeof vi.spyOn>;

beforeAll(() => {
  process.env.BANK_ALLOWED_GROUP_IDS = " gAllowed , ,";
});

beforeEach(async () => {
  fetchSpy = vi
    .spyOn(globalThis, "fetch")
    .mockRejectedValue(new Error("Cap test pot cridar Enable Banking"));

  const firestore = db();
  const batch = firestore.batch();
  batch.set(firestore.doc("groups/gAllowed"), { memberIds: ["alice"], ownerId: "alice" });
  batch.set(firestore.doc("groups/gOther"), { memberIds: ["mallory"], ownerId: "mallory" });
  batch.set(firestore.doc("users/alice"), { currentGroupId: "gAllowed" });
  batch.set(firestore.doc("users/mallory"), { currentGroupId: "gOther" });
  batch.set(firestore.doc("users/eve"), { currentGroupId: "gAllowed" });
  batch.set(firestore.doc("users/nobody"), { currentGroupId: null });
  await batch.commit();
});

afterEach(() => {
  fetchSpy.mockRestore();
});

describe("parseAllowedGroupIds", () => {
  it("ignora espais i elements buits", () => {
    expect([...parseAllowedGroupIds(" a, b ,,c ,")]).toEqual(["a", "b", "c"]);
  });

  it("buit o sense definir = cap grup", () => {
    expect(parseAllowedGroupIds("").size).toBe(0);
    expect(parseAllowedGroupIds(undefined).size).toBe(0);
  });
});

describe("requireBankAccess", () => {
  const allowed = new Set(["gAllowed"]);

  it("un membre d'un grup permès hi té accés", async () => {
    await expect(requireBankAccess(db(), "alice", allowed)).resolves.toBe("gAllowed");
  });

  it("un membre d'un grup no permès queda bloquejat amb el motiu propi", async () => {
    await expect(requireBankAccess(db(), "mallory", allowed)).rejects.toMatchObject({
      code: "permission-denied",
      message: "La connexió bancària encara no està disponible per al teu grup.",
      details: { reason: BANK_NOT_ENABLED },
    });
  });

  it("apuntar el currentGroupId a un grup permès sense ser-ne membre no serveix", async () => {
    await expect(requireBankAccess(db(), "eve", allowed)).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  it("sense grup actiu no hi ha accés", async () => {
    await expect(requireBankAccess(db(), "nobody", allowed)).rejects.toMatchObject({
      code: "failed-precondition",
    });
  });

  it("amb la llista buida es bloqueja tothom, també els membres", async () => {
    await expect(requireBankAccess(db(), "alice", new Set())).rejects.toMatchObject({
      details: { reason: BANK_NOT_ENABLED },
    });
  });
});

describe("les 6 Functions bancàries", () => {
  for (const [name, fn, data] of FUNCTIONS) {
    it(`${name}: un grup no permès queda bloquejat sense cridar Enable Banking`, async () => {
      await expect(fn.run(callAs("mallory", data))).rejects.toMatchObject({
        code: "permission-denied",
        details: { reason: BANK_NOT_ENABLED },
      });
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it(`${name}: un no membre amb currentGroupId falsejat queda bloquejat`, async () => {
      await expect(fn.run(callAs("eve", data))).rejects.toMatchObject({
        code: "permission-denied",
      });
      expect(fetchSpy).not.toHaveBeenCalled();
    });
  }

  it("un membre d'un grup permès passa el control (listBankAccounts arriba a les connexions)", async () => {
    // Sense cap connexió desada: l'error ja és el de "connecta el banc", no el de bloqueig.
    await expect(listBankAccounts.run(callAs("alice"))).rejects.toMatchObject({
      code: "failed-precondition",
      message: "No hi ha cap sessió bancària. Connecta el banc primer.",
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("un membre d'un grup permès passa el control (updateBankAccountConfig valida les dades)", async () => {
    await expect(updateBankAccountConfig.run(callAs("alice", {}))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });
});
