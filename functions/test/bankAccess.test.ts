/**
 * Control d'accés de les Functions bancàries. S'executa amb `npm run test:rules`
 * (emulador de Firestore, projecte fictici `demo-centim`): cap crida surt cap a
 * Enable Banking.
 *
 * Personatges:
 *  - alice:   membre d'un grup de la llista de transició (gAllowed, sense app pròpia)
 *  - mallory: membre d'un grup sense aplicació pròpia ni a la llista (gOther)
 *  - eve:     apunta el seu currentGroupId a gAllowed sense ser-ne membre
 *  - nobody:  sense grup
 */
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

import { parseAllowedGroupIds } from "../src/bankConnections.js";
import { NO_BANK_APP, requireBankAccess } from "../src/bankApp.js";
import { startBankAuth } from "../src/startBankAuth.js";
import { finalizeBankSession } from "../src/finalizeBankSession.js";
import { fetchBankTransactions } from "../src/fetchBankTransactions.js";
import { listBankAccounts } from "../src/listBankAccounts.js";
import { inspectBankSessionAccounts } from "../src/inspectBankSessionAccounts.js";
import { updateBankAccountConfig } from "../src/updateBankAccountConfig.js";
import { listAspsps } from "../src/bankAppAdmin.js";
import { adminDb as db, callAs, clearFirestore } from "./helpers.js";

// Mateixes dades que enviaria l'app per a cada Function.
const FUNCTIONS = [
  ["startBankAuth", startBankAuth, { newConnection: true, aspspName: "BBVA" }],
  ["finalizeBankSession", finalizeBankSession, { code: "c", state: "s" }],
  ["fetchBankTransactions", fetchBankTransactions, {}],
  ["listBankAccounts", listBankAccounts, {}],
  ["inspectBankSessionAccounts", inspectBankSessionAccounts, { connectionId: "caixabank" }],
  ["updateBankAccountConfig", updateBankAccountConfig, { accountKey: "k", sync: true }],
  ["listAspsps", listAspsps, { country: "ES" }],
] as const;

let fetchSpy: ReturnType<typeof vi.spyOn>;

beforeAll(() => {
  process.env.BANK_ALLOWED_GROUP_IDS = " gAllowed , ,";
});

beforeEach(async () => {
  await clearFirestore();
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
  it("un grup de la llista de transició fa servir l'aplicació global", async () => {
    await expect(requireBankAccess(db(), "alice")).resolves.toMatchObject({
      groupId: "gAllowed",
      app: null,
      legacy: true,
    });
  });

  it("un grup sense aplicació pròpia ni a la llista queda bloquejat amb el motiu propi", async () => {
    await expect(requireBankAccess(db(), "mallory")).rejects.toMatchObject({
      code: "failed-precondition",
      message: "El teu grup encara no té configurada la connexió bancària.",
      details: { reason: NO_BANK_APP },
    });
  });

  it("apuntar el currentGroupId a un grup amb accés sense ser-ne membre no serveix", async () => {
    await expect(requireBankAccess(db(), "eve")).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  it("sense grup actiu no hi ha accés", async () => {
    await expect(requireBankAccess(db(), "nobody")).rejects.toMatchObject({
      code: "failed-precondition",
    });
  });

  it("amb la llista buida, un grup sense app pròpia queda bloquejat", async () => {
    process.env.BANK_ALLOWED_GROUP_IDS = "";
    try {
      await expect(requireBankAccess(db(), "alice")).rejects.toMatchObject({
        details: { reason: NO_BANK_APP },
      });
    } finally {
      process.env.BANK_ALLOWED_GROUP_IDS = "gAllowed";
    }
  });
});

describe("les Functions bancàries", () => {
  for (const [name, fn, data] of FUNCTIONS) {
    it(`${name}: un grup sense aplicació queda bloquejat sense cridar Enable Banking`, async () => {
      await expect(fn.run(callAs("mallory", data))).rejects.toMatchObject({
        code: "failed-precondition",
        details: { reason: NO_BANK_APP },
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

  it("un grup amb accés passa el control (listBankAccounts, sense connexions)", async () => {
    await expect(listBankAccounts.run(callAs("alice"))).resolves.toMatchObject({
      connections: [],
      groupAccounts: [],
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("un grup amb accés passa el control (updateBankAccountConfig valida les dades)", async () => {
    await expect(updateBankAccountConfig.run(callAs("alice", {}))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });
});
