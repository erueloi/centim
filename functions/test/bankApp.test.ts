/**
 * Fase 1: una aplicació d'Enable Banking per grup. Emulador de Firestore
 * (`npm run test:rules`) + Enable Banking simulat: cap crida surt a la xarxa.
 *
 * Personatges:
 *  - alice: owner de gA · bob: membre de gA
 *  - mallory: owner de gB (sense aplicació)
 *  - eloi: owner de gLegacy (llista de transició, aplicació global) · jose: membre
 */
import { logger } from "firebase-functions/v2";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

import { decryptSecret, parseKeyring } from "../src/bankAppCrypto.js";
import { APP_CHANGED, NOT_GROUP_OWNER, NO_BANK_APP } from "../src/bankApp.js";
import {
  deleteBankAppCredentials,
  getBankSetup,
  listAspsps,
  saveBankAppCredentials,
} from "../src/bankAppAdmin.js";
import { startBankAuth } from "../src/startBankAuth.js";
import { finalizeBankSession } from "../src/finalizeBankSession.js";
import { fetchBankTransactions } from "../src/fetchBankTransactions.js";
import { listBankAccounts } from "../src/listBankAccounts.js";
import {
  onGroupDeleted,
  onGroupMembersChanged,
  removedMembers,
} from "../src/groupTriggers.js";
import {
  EbCall,
  EbResponse,
  PRODUCTION_CALLBACK,
  adminDb as db,
  callAs,
  clearFirestore,
  defaultEbHandler,
  generatePem,
  mockEnableBanking,
  pemFragments,
  testKeyring,
} from "./helpers.js";

const GROUP_APP_ID = "11111111-2222-4333-8444-555555555555";
const OTHER_APP_ID = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee";
const LEGACY_APP_ID = "99999999-8888-4777-8666-555555555555";
const GROUP_PEM = generatePem();
const OTHER_PEM = generatePem();
const LEGACY_PEM = generatePem();
const KEYRING = testKeyring();

let eb: { calls: EbCall[]; spy: ReturnType<typeof vi.spyOn> };
let logged: unknown[];

function useEnableBanking(overrides: Partial<Record<string, EbResponse>> = {}) {
  eb.spy.mockRestore();
  eb = mockEnableBanking(defaultEbHandler(overrides));
}

/** Cap valor (resposta, log, document...) pot contenir cap tros de cap clau. */
function expectNoKeyIn(value: unknown) {
  const text = JSON.stringify(value) ?? "";
  expect(text).not.toContain("PRIVATE KEY");
  for (const pem of [GROUP_PEM, OTHER_PEM, LEGACY_PEM]) {
    for (const fragment of pemFragments(pem)) {
      expect(text).not.toContain(fragment);
    }
  }
}

async function seedConnection(uid: string, id: string, data: Record<string, unknown>) {
  await db().doc(`users/${uid}/bank_connections/${id}`).set({ connectionId: id, ...data });
}

const account = (n: number) => ({
  uid: `acc-${n}`,
  identification_hash: `hash-${n}`,
  account_id: { iban: `ES91210004184502000${String(n).padStart(5, "0")}` },
  name: `Compte ${n}`,
  currency: "EUR",
});

beforeAll(() => {
  process.env.BANK_ALLOWED_GROUP_IDS = "gLegacy";
  process.env.ENABLEBANKING_ENV = "production";
  process.env.ENABLEBANKING_APP_ID_PROD = LEGACY_APP_ID;
  process.env.ENABLEBANKING_PEM_PROD = LEGACY_PEM;
  process.env.BANK_APP_MASTER_KEYRING = KEYRING;
});

beforeEach(async () => {
  await clearFirestore();
  eb = mockEnableBanking(defaultEbHandler());

  logged = [];
  for (const method of ["debug", "info", "log", "warn", "error"] as const) {
    vi.spyOn(logger, method).mockImplementation((...args: unknown[]) => {
      logged.push(args);
    });
    vi.spyOn(console, method).mockImplementation((...args: unknown[]) => {
      logged.push(args);
    });
  }

  const batch = db().batch();
  batch.set(db().doc("groups/gA"), { memberIds: ["alice", "bob"], ownerId: "alice" });
  batch.set(db().doc("groups/gB"), { memberIds: ["mallory"], ownerId: "mallory" });
  batch.set(db().doc("groups/gLegacy"), { memberIds: ["eloi", "jose"], ownerId: "eloi" });
  for (const [uid, groupId] of [
    ["alice", "gA"],
    ["bob", "gA"],
    ["mallory", "gB"],
    ["eloi", "gLegacy"],
    ["jose", "gLegacy"],
  ]) {
    batch.set(db().doc(`users/${uid}`), { currentGroupId: groupId, email: `${uid}@example.com` });
  }
  await batch.commit();
});

afterEach(() => {
  // Cap test pot deixar escapar la clau als logs.
  expectNoKeyIn(logged);
  vi.restoreAllMocks();
});

async function saveGroupApp(appId = GROUP_APP_ID, pem = GROUP_PEM, uid = "alice") {
  return saveBankAppCredentials.run(callAs(uid, { appId, pem }));
}

// ---------------------------------------------------------------------------

describe("desar credencials", () => {
  it("l'owner les desa: validades amb /application i xifrades amb el groupId", async () => {
    const result = await saveGroupApp();

    expect(result).toMatchObject({ appIdShort: "11111111…", env: "production", appName: "Cèntim Llar" });
    expectNoKeyIn(result);

    const application = eb.calls.find((c) => c.path === "/application");
    expect(application?.kid).toBe(GROUP_APP_ID);

    const stored = (await db().doc("bank_apps/gA").get()).data()!;
    expect(stored).toMatchObject({ appId: GROUP_APP_ID, env: "production", validatedBy: "alice" });
    expect(stored.encryptedKey.keyVersion).toBe("v1");
    expectNoKeyIn(stored);
    expect(decryptSecret(stored.encryptedKey, "gA", parseKeyring(KEYRING))).toBe(GROUP_PEM);
    expect(() => decryptSecret(stored.encryptedKey, "gB", parseKeyring(KEYRING))).toThrow();
  });

  it("accepta una clau PKCS#1 i la desa normalitzada a PKCS#8", async () => {
    const pkcs1 = generatePem("pkcs1");
    await saveGroupApp(GROUP_APP_ID, pkcs1);
    const stored = (await db().doc("bank_apps/gA").get()).data()!;
    const pem = decryptSecret(stored.encryptedKey, "gA", parseKeyring(KEYRING));
    expect(pem).toContain("-----BEGIN PRIVATE KEY-----");
  });

  it("un membre que no és owner no pot desar credencials", async () => {
    await expect(saveGroupApp(GROUP_APP_ID, GROUP_PEM, "bob")).rejects.toMatchObject({
      code: "permission-denied",
      details: { reason: NOT_GROUP_OWNER },
    });
    expect((await db().doc("bank_apps/gA").get()).exists).toBe(false);
    expect(eb.calls).toHaveLength(0);
  });

  it("algú de fora del grup no pot desar-ne les credencials (currentGroupId falsejat)", async () => {
    await db().doc("users/mallory").set({ currentGroupId: "gA" });
    await expect(saveGroupApp(OTHER_APP_ID, OTHER_PEM, "mallory")).rejects.toMatchObject({
      code: "permission-denied",
    });
    expect((await db().doc("bank_apps/gA").get()).exists).toBe(false);
  });

  it("rebutja un app id o una clau invàlids sense cridar Enable Banking", async () => {
    await expect(saveGroupApp("no-es-un-uuid")).rejects.toMatchObject({ code: "invalid-argument" });
    await expect(saveGroupApp(GROUP_APP_ID, "no és una clau")).rejects.toMatchObject({
      code: "invalid-argument",
    });
    await expect(
      saveGroupApp(GROUP_APP_ID, "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----")
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(eb.calls).toHaveLength(0);
  });

  it("si l'app id i la clau no casen (401), ho diu clarament", async () => {
    useEnableBanking({ "GET /application": { status: 401, body: {} } });
    await expect(saveGroupApp()).rejects.toMatchObject({
      code: "invalid-argument",
      message: expect.stringContaining("no reconeix"),
    });
    expect((await db().doc("bank_apps/gA").get()).exists).toBe(false);
  });

  it("exigeix que l'aplicació estigui activa", async () => {
    useEnableBanking({
      "GET /application": {
        body: { environment: "PRODUCTION", active: false, redirect_urls: [PRODUCTION_CALLBACK] },
      },
    });
    await expect(saveGroupApp()).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("exigeix la redirect URL de producció", async () => {
    useEnableBanking({
      "GET /application": {
        body: {
          environment: "PRODUCTION",
          active: true,
          redirect_urls: ["http://localhost:5000/bank-callback"],
        },
      },
    });
    await expect(saveGroupApp()).rejects.toMatchObject({
      code: "failed-precondition",
      message: expect.stringContaining(PRODUCTION_CALLBACK),
    });
  });

  it("en sandbox accepta també el callback de localhost", async () => {
    useEnableBanking({
      "GET /application": {
        body: {
          environment: "SANDBOX",
          active: true,
          redirect_urls: ["http://localhost:5000/bank-callback"],
        },
      },
    });
    await expect(saveGroupApp()).resolves.toMatchObject({ env: "sandbox" });
  });
});

describe("getBankSetup", () => {
  it("un membre veu l'estat però mai la clau", async () => {
    await saveGroupApp();
    const setup = await getBankSetup.run(callAs("bob"));
    expect(setup).toMatchObject({
      configured: true,
      source: "group",
      appIdShort: "11111111…",
      env: "production",
      isOwner: false,
    });
    expectNoKeyIn(setup);
    expect(JSON.stringify(setup)).not.toContain(GROUP_APP_ID);
  });

  it("un grup sense aplicació ho diu, i l'owner ho sap", async () => {
    await expect(getBankSetup.run(callAs("mallory"))).resolves.toMatchObject({
      configured: false,
      source: null,
      isOwner: true,
    });
  });

  it("un grup de la llista de transició apareix com a aplicació global", async () => {
    await expect(getBankSetup.run(callAs("jose"))).resolves.toMatchObject({
      configured: true,
      source: "legacy",
      isOwner: false,
    });
  });
});

describe("cada grup fa servir la seva aplicació", () => {
  it("startBankAuth signa amb l'aplicació del grup, amb el banc triat i la seva validesa màxima", async () => {
    await saveGroupApp();
    eb.calls.length = 0;

    const result = await startBankAuth.run(
      callAs("bob", { newConnection: true, aspspName: "BBVA", aspspCountry: "ES" })
    );
    expect(result).toMatchObject({ aspspName: "BBVA", authUrl: expect.stringContaining("https://") });
    expect(result.connectionId).toMatch(/^bbva-/);
    expectNoKeyIn(result);

    expect(eb.calls.map((c) => c.kid)).toEqual(eb.calls.map(() => GROUP_APP_ID));
    const auth = eb.calls.find((c) => c.path === "/auth")!;
    expect(auth.body).toMatchObject({ aspsp: { name: "BBVA", country: "ES" }, psu_type: "personal" });
    // maximum_consent_validity de BBVA (90 dies) menys el marge d'1 hora.
    const seconds = (Date.parse((auth.body as { access: { valid_until: string } }).access.valid_until) - Date.now()) / 1000;
    expect(seconds).toBeGreaterThan(7776000 - 3600 - 60);
    expect(seconds).toBeLessThanOrEqual(7776000 - 3600);

    const conn = (await db().doc(`users/bob/bank_connections/${result.connectionId}`).get()).data()!;
    expect(conn).toMatchObject({
      groupId: "gA",
      aspspName: "BBVA",
      aspspCountry: "ES",
      pendingAppId: GROUP_APP_ID,
      requiredPsuHeaders: ["psu-ip-address"],
    });
  });

  it("multi banc: dues connexions amb dos bancs diferents (Mock ASPSP i BBVA)", async () => {
    await saveGroupApp();
    const mock = await startBankAuth.run(
      callAs("alice", { newConnection: true, aspspName: "Mock ASPSP" })
    );
    const bbva = await startBankAuth.run(callAs("alice", { newConnection: true, aspspName: "BBVA" }));
    expect(mock.connectionId).toMatch(/^mock-aspsp-/);
    expect(bbva.connectionId).toMatch(/^bbva-/);
    const auths = eb.calls.filter((c) => c.path === "/auth").map((c) => (c.body as { aspsp: { name: string } }).aspsp.name);
    expect(auths).toEqual(["Mock ASPSP", "BBVA"]);
  });

  it("un altre grup no pot fer servir aquesta aplicació: sense app pròpia, queda bloquejat", async () => {
    await saveGroupApp();
    eb.calls.length = 0;
    await expect(
      startBankAuth.run(callAs("mallory", { newConnection: true, aspspName: "BBVA" }))
    ).rejects.toMatchObject({ details: { reason: NO_BANK_APP } });
    expect(eb.calls).toHaveLength(0);
  });

  it("una connexió nova exigeix triar el banc", async () => {
    await saveGroupApp();
    await expect(startBankAuth.run(callAs("alice", { newConnection: true }))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });

  it("listAspsps: només bancs per a particulars, i el catàleg es desa 24 h", async () => {
    await saveGroupApp();
    eb.calls.length = 0;
    const first = await listAspsps.run(callAs("bob", { country: "es" }));
    const second = await listAspsps.run(callAs("alice", { country: "ES" }));
    expect(first.aspsps.map((a: { name: string }) => a.name)).toEqual([
      "BBVA",
      "CaixaBank",
      "Mock ASPSP",
    ]);
    expect(second).toEqual(first);
    expect(eb.calls.filter((c) => c.path === "/aspsps")).toHaveLength(1);
  });

  it("finalize desa l'aplicació de la sessió; amb 0 comptes avisa que cal enllaçar-los", async () => {
    await saveGroupApp();
    const start = await startBankAuth.run(callAs("bob", { newConnection: true, aspspName: "BBVA" }));
    const pending = await db().doc(`users/bob/bank_connections/${start.connectionId}`).get();
    useEnableBanking({ "POST /sessions": { body: { session_id: "sess-buida", accounts: [] } } });

    const done = await finalizeBankSession.run(
      callAs("bob", { code: "code", state: pending.get("pendingState") })
    );
    expect(done).toMatchObject({ accountCount: 0, noLinkedAccounts: true, aspspName: "BBVA" });
    expectNoKeyIn(done);
    expect(JSON.stringify(done)).not.toContain("sess-buida");
    const conn = (await pending.ref.get()).data()!;
    expect(conn).toMatchObject({ appId: GROUP_APP_ID, status: "connected", sessionId: "sess-buida" });
    expect(conn.pendingState).toBeUndefined();
  });

  it("si l'aplicació canvia enmig de la SCA, finalize no barreja aplicacions", async () => {
    await saveGroupApp();
    const start = await startBankAuth.run(callAs("bob", { newConnection: true, aspspName: "BBVA" }));
    const pending = await db().doc(`users/bob/bank_connections/${start.connectionId}`).get();
    await saveGroupApp(OTHER_APP_ID, OTHER_PEM);
    eb.calls.length = 0;

    await expect(
      finalizeBankSession.run(callAs("bob", { code: "code", state: pending.get("pendingState") }))
    ).rejects.toMatchObject({ details: { reason: APP_CHANGED } });
    expect(eb.calls.filter((c) => c.path === "/sessions")).toHaveLength(0);
  });
});

describe("canvi d'aplicació i comptes accessibles", () => {
  it("una connexió creada amb una altra aplicació cal reconnectar-la, sense estranyeses", async () => {
    await saveGroupApp();
    await seedConnection("bob", "bbva-old", {
      groupId: "gA",
      appId: OTHER_APP_ID,
      sessionId: "sess-old",
      aspspName: "BBVA",
      accounts: [account(1)],
    });

    const list = await listBankAccounts.run(callAs("bob"));
    expect(list.connections[0]).toMatchObject({ needsReconnect: true, reconnectReason: APP_CHANGED });

    eb.calls.length = 0;
    await expect(fetchBankTransactions.run(callAs("bob"))).rejects.toMatchObject({
      code: "failed-precondition",
      details: { needsReauth: true, reason: APP_CHANGED, connectionId: "bbva-old" },
    });
    expect(eb.calls).toHaveLength(0);
  });

  it("canviar les credencials marca les connexions antigues i en revoca les sessions", async () => {
    await saveGroupApp();
    await seedConnection("bob", "bbva-1", {
      groupId: "gA",
      appId: GROUP_APP_ID,
      sessionId: "sess-1",
      accounts: [account(1)],
    });
    eb.calls.length = 0;

    const result = await saveGroupApp(OTHER_APP_ID, OTHER_PEM);
    expect(result).toMatchObject({ connectionsKept: 0, connectionsToReconnect: 1 });

    const revoke = eb.calls.find((c) => c.method === "DELETE");
    expect(revoke).toMatchObject({ path: "/sessions/sess-1", kid: GROUP_APP_ID });
    const conn = (await db().doc("users/bob/bank_connections/bbva-1").get()).data()!;
    expect(conn).toMatchObject({ status: "needs-reconnect", reconnectReason: "app-changed" });
    expect(conn.sessionId).toBeUndefined();
  });

  it("comptes accessibles: unió de les connexions actives de tots els membres, sense duplicats", async () => {
    await saveGroupApp();
    await db().doc("users/bob").set({ name: "Bob" }, { merge: true });
    await seedConnection("alice", "c-a", {
      groupId: "gA", appId: GROUP_APP_ID, sessionId: "s-a", aspspName: "CaixaBank",
      accounts: [account(1), account(2)],
    });
    await seedConnection("bob", "c-b", {
      groupId: "gA", appId: GROUP_APP_ID, sessionId: "s-b", aspspName: "BBVA",
      accounts: [account(2), account(3)],
    });
    // No compten: una d'una altra aplicació i una d'un altre grup.
    await seedConnection("bob", "c-old", {
      groupId: "gA", appId: OTHER_APP_ID, sessionId: "s-old", accounts: [account(4)],
    });
    await seedConnection("mallory", "c-m", {
      groupId: "gB", appId: GROUP_APP_ID, sessionId: "s-m", accounts: [account(5)],
    });

    const list = await listBankAccounts.run(callAs("alice"));
    expect(list.groupAccounts).toHaveLength(3);
    expect(list.groupAccounts).toContainEqual({
      ibanMasked: "ES****0003",
      name: "Compte 3",
      aspspName: "BBVA",
      memberName: "Bob",
    });
    // Cap id de sessió ni IBAN sencer enlloc; i als comptes del grup, tampoc
    // la clau estable del compte (només la necessiten els comptes propis).
    const text = JSON.stringify(list);
    for (const leak of ["s-a", "s-b", "s-old", "ES912100"]) {
      expect(text).not.toContain(leak);
    }
    expect(JSON.stringify(list.groupAccounts)).not.toContain("hash-");
  });
});

describe("migració del grup de transició sense reconnectar", () => {
  beforeEach(async () => {
    // Connexions creades amb l'aplicació global: sense appId.
    await seedConnection("eloi", "caixabank", {
      groupId: "gLegacy", sessionId: "sess-eloi", aspspName: "CaixaBank", accounts: [account(1)],
    });
    await seedConnection("jose", "caixabank-2", {
      groupId: "gLegacy", sessionId: "sess-jose", aspspName: "CaixaBank", accounts: [account(2)],
    });
  });

  it("abans de migrar, el grup fa servir l'aplicació global i les connexions són vàlides", async () => {
    const list = await listBankAccounts.run(callAs("jose"));
    expect(list.connections[0]).toMatchObject({ needsReconnect: false });
    await startBankAuth.run(callAs("eloi", { connectionId: "caixabank" }));
    expect(eb.calls.find((c) => c.path === "/auth")?.kid).toBe(LEGACY_APP_ID);
  });

  it("amb el MATEIX app id i clau, les connexions es conserven (només s'hi afegeix l'appId)", async () => {
    const result = await saveGroupApp(LEGACY_APP_ID, LEGACY_PEM, "eloi");
    expect(result).toMatchObject({ connectionsKept: 2, connectionsToReconnect: 0 });
    expect(eb.calls.filter((c) => c.method === "DELETE")).toHaveLength(0);

    for (const [uid, id, session] of [["eloi", "caixabank", "sess-eloi"], ["jose", "caixabank-2", "sess-jose"]]) {
      const conn = (await db().doc(`users/${uid}/bank_connections/${id}`).get()).data()!;
      expect(conn).toMatchObject({ appId: LEGACY_APP_ID, sessionId: session });
      expect(conn.status).toBeUndefined();
    }
    await expect(getBankSetup.run(callAs("jose"))).resolves.toMatchObject({ source: "group" });
    const list = await listBankAccounts.run(callAs("jose"));
    expect(list.connections[0]).toMatchObject({ needsReconnect: false });
  });

  it("amb una aplicació diferent, cal reconnectar i se'n revoquen les sessions amb l'app global", async () => {
    const result = await saveGroupApp(OTHER_APP_ID, OTHER_PEM, "eloi");
    expect(result).toMatchObject({ connectionsKept: 0, connectionsToReconnect: 2 });
    const revoked = eb.calls.filter((c) => c.method === "DELETE");
    expect(revoked.map((c) => c.kid)).toEqual([LEGACY_APP_ID, LEGACY_APP_ID]);
  });
});

describe("eliminar credencials", () => {
  it("un membre que no és owner no les pot eliminar", async () => {
    await saveGroupApp();
    await expect(deleteBankAppCredentials.run(callAs("bob"))).rejects.toMatchObject({
      code: "permission-denied",
      details: { reason: NOT_GROUP_OWNER },
    });
    expect((await db().doc("bank_apps/gA").get()).exists).toBe(true);
  });

  it("l'owner les elimina: sessions revocades i connexions per reconnectar", async () => {
    await saveGroupApp();
    await seedConnection("bob", "c-b", {
      groupId: "gA", appId: GROUP_APP_ID, sessionId: "s-b", accounts: [account(1)],
    });
    eb.calls.length = 0;

    const result = await deleteBankAppCredentials.run(callAs("alice"));
    expect(result).toEqual({ deleted: true, connectionsToReconnect: 1 });
    expect((await db().doc("bank_apps/gA").get()).exists).toBe(false);
    expect(eb.calls.find((c) => c.method === "DELETE")).toMatchObject({
      path: "/sessions/s-b",
      kid: GROUP_APP_ID,
    });
    const conn = (await db().doc("users/bob/bank_connections/c-b").get()).data()!;
    expect(conn).toMatchObject({ status: "needs-reconnect", reconnectReason: "app-removed" });

    await expect(listBankAccounts.run(callAs("bob"))).rejects.toMatchObject({
      details: { reason: NO_BANK_APP },
    });
  });
});

describe("membres que surten i grups esborrats", () => {
  it("removedMembers", () => {
    expect(removedMembers(["a", "b", "c"], ["a", "c"])).toEqual(["b"]);
    expect(removedMembers(["a"], ["a", "d"])).toEqual([]);
    expect(removedMembers(undefined, ["a"])).toEqual([]);
  });

  it("qui surt del grup en perd les connexions (inactives i sessions revocades)", async () => {
    await saveGroupApp();
    await seedConnection("bob", "c-b", {
      groupId: "gA", appId: GROUP_APP_ID, sessionId: "s-b", accounts: [account(1)],
    });
    await seedConnection("bob", "c-altre-grup", {
      groupId: "gZ", appId: GROUP_APP_ID, sessionId: "s-z", accounts: [account(2)],
    });
    await seedConnection("alice", "c-a", {
      groupId: "gA", appId: GROUP_APP_ID, sessionId: "s-a", accounts: [account(3)],
    });
    eb.calls.length = 0;

    const snap = (memberIds: string[]) => ({ get: (field: string) => (field === "memberIds" ? memberIds : undefined) });
    await onGroupMembersChanged.run({
      params: { groupId: "gA" },
      data: { before: snap(["alice", "bob"]), after: snap(["alice"]) },
    } as never);

    const bob = (await db().doc("users/bob/bank_connections/c-b").get()).data()!;
    expect(bob).toMatchObject({ status: "inactive", inactiveReason: "left-group" });
    expect(bob.sessionId).toBeUndefined();
    expect(eb.calls.filter((c) => c.method === "DELETE").map((c) => c.path)).toEqual(["/sessions/s-b"]);
    // Ni la connexió de bob d'un altre grup ni la d'alice es toquen.
    expect((await db().doc("users/bob/bank_connections/c-altre-grup").get()).get("sessionId")).toBe("s-z");
    expect((await db().doc("users/alice/bank_connections/c-a").get()).get("sessionId")).toBe("s-a");
  });

  it("esborrar el grup esborra també bank_apps/{groupId}", async () => {
    await saveGroupApp();
    await onGroupDeleted.run({ params: { groupId: "gA" } } as never);
    expect((await db().doc("bank_apps/gA").get()).exists).toBe(false);
  });
});
