/**
 * Proves contra el SANDBOX real d'Enable Banking. Només s'executen si hi ha
 * EB_SANDBOX_APP_ID i EB_SANDBOX_PEM_PATH (la clau es llegeix del fitxer i
 * mai s'imprimeix). A la CI no hi són i aquests tests se salten.
 *
 * La SCA (autenticar-se al banc simulat) no es pot automatitzar: aquí es
 * prova fins a obtenir la URL d'autorització per a dos bancs diferents.
 */
import { readFileSync } from "node:fs";
import { beforeAll, beforeEach, describe, expect, it } from "vitest";

import {
  deleteBankAppCredentials,
  getBankSetup,
  listAspsps,
  saveBankAppCredentials,
} from "../src/bankAppAdmin.js";
import { startBankAuth } from "../src/startBankAuth.js";
import { adminDb as db, callAs, clearFirestore, pemFragments, testKeyring } from "./helpers.js";

const appId = process.env.EB_SANDBOX_APP_ID;
const pemPath = process.env.EB_SANDBOX_PEM_PATH;

describe.skipIf(!appId || !pemPath)("sandbox real d'Enable Banking", () => {
  let pem: string;

  beforeAll(() => {
    pem = readFileSync(pemPath!, "utf8");
    process.env.BANK_APP_MASTER_KEYRING = testKeyring();
    process.env.BANK_ALLOWED_GROUP_IDS = "";
  });

  beforeEach(async () => {
    await clearFirestore();
    await db().doc("groups/gS").set({ memberIds: ["owner", "member"], ownerId: "owner" });
    await db().doc("users/owner").set({ currentGroupId: "gS" });
    await db().doc("users/member").set({ currentGroupId: "gS" });
  });

  it("valida i desa les credencials del sandbox amb GET /application", { timeout: 30000 }, async () => {
    const result = await saveBankAppCredentials.run(callAs("owner", { appId, pem }));
    expect(result).toMatchObject({ env: "sandbox" });
    const text = JSON.stringify(result);
    for (const fragment of pemFragments(pem)) expect(text).not.toContain(fragment);

    await expect(getBankSetup.run(callAs("member"))).resolves.toMatchObject({
      configured: true,
      env: "sandbox",
      isOwner: false,
    });
  });

  it("multi banc: el catàleg d'ES té almenys dos bancs i se'n pot iniciar l'autorització", { timeout: 60000 }, async () => {
    await saveBankAppCredentials.run(callAs("owner", { appId, pem }));

    const { aspsps } = await listAspsps.run(callAs("member", { country: "ES" }));
    const names = aspsps.map((a: { name: string }) => a.name);
    expect(names).toEqual(expect.arrayContaining(["Mock ASPSP", "BBVA"]));

    for (const aspspName of ["Mock ASPSP", "BBVA"]) {
      const start = await startBankAuth.run(
        callAs("member", {
          newConnection: true,
          aspspName,
          redirectUrl: "http://localhost:5000/bank-callback",
        })
      );
      expect(start.aspspName).toBe(aspspName);
      expect(start.authUrl).toMatch(/^https:\/\//);
    }
  });

  it("l'owner pot eliminar-les", { timeout: 30000 }, async () => {
    await saveBankAppCredentials.run(callAs("owner", { appId, pem }));
    await expect(deleteBankAppCredentials.run(callAs("owner"))).resolves.toMatchObject({ deleted: true });
    await expect(getBankSetup.run(callAs("member"))).resolves.toMatchObject({ configured: false });
  });
});
