/**
 * Aïllament multi-tenant entre llars. S'executa amb `npm run test:rules`, que
 * arrenca l'emulador de Firestore amb el projecte fictici `demo-centim`.
 *
 * Personatges:
 *  - alice: owner de la Llar A (gA)
 *  - bob:   membre (no owner) de la Llar A
 *  - mallory: atacant, owner de la Llar B (gB)
 *  - carol: usuària registrada sense grup
 */
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  documentId,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
  type Firestore,
} from "firebase/firestore";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore as getAdminFirestore } from "firebase-admin/firestore";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";

import { joinGroupWithCodeImpl } from "../src/joinGroup.js";

const PROJECT_ID = "demo-centim";
const ROOT_COLLECTIONS = [
  "transactions",
  "budgets",
  "billing_cycles",
  "savings_goals",
] as const;

let testEnv: RulesTestEnvironment;

const asUser = (uid: string): Firestore =>
  testEnv.authenticatedContext(uid).firestore() as unknown as Firestore;
const alice = () => asUser("alice");
const bob = () => asUser("bob");
const mallory = () => asUser("mallory");
const carol = () => asUser("carol");

function adminDb() {
  if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
  return getAdminFirestore();
}

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(
        fileURLToPath(new URL("../../firestore.rules", import.meta.url)),
        "utf8"
      ),
    },
  });
});

afterAll(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore() as unknown as Firestore;
    await setDoc(doc(db, "groups/gA"), {
      id: "gA",
      name: "Llar A",
      memberIds: ["alice", "bob"],
      ownerId: "alice",
      inviteCode: "AAAAAA",
      totalAssets: 0,
    });
    await setDoc(doc(db, "groups/gB"), {
      id: "gB",
      name: "Llar B",
      memberIds: ["mallory"],
      ownerId: "mallory",
      inviteCode: "BBBBBB",
      totalAssets: 0,
    });
    await setDoc(doc(db, "users/alice"), {
      uid: "alice",
      email: "alice@example.com",
      name: "Alice",
      currentGroupId: "gA",
    });
    await setDoc(doc(db, "users/bob"), {
      uid: "bob",
      email: "bob@example.com",
      currentGroupId: "gA",
    });
    await setDoc(doc(db, "users/mallory"), {
      uid: "mallory",
      email: "mallory@example.com",
      currentGroupId: "gB",
    });
    await setDoc(doc(db, "users/carol"), {
      uid: "carol",
      email: "carol@example.com",
      currentGroupId: null,
    });
    for (const col of ROOT_COLLECTIONS) {
      await setDoc(doc(db, `${col}/${col}A`), {
        groupId: "gA",
        amount: 10,
        categoryId: "cat1",
        categoryName: "Casa",
      });
    }
    await setDoc(doc(db, "groups/gA/categories/cat1"), {
      name: "Casa",
      order: 0,
      subcategories: [],
    });
    await setDoc(doc(db, "groups/gA/categories/cat2"), {
      name: "Oci",
      order: 1,
      subcategories: [],
    });
  });
});

// ---------------------------------------------------------------------------
// ATACS: tots han de quedar BLOQUEJATS
// ---------------------------------------------------------------------------

describe("atac 1: llegir o llistar grups aliens", () => {
  it("no es poden llistar tots els grups", async () => {
    await assertFails(getDocs(collection(mallory(), "groups")));
  });

  it("no es pot buscar un grup pel codi d'invitació", async () => {
    await assertFails(
      getDocs(query(collection(mallory(), "groups"), where("inviteCode", "==", "AAAAAA")))
    );
  });

  it("no es pot llegir un grup del qual no ets membre", async () => {
    await assertFails(getDoc(doc(mallory(), "groups/gA")));
  });

  it("un usuari sense grup tampoc pot llistar grups", async () => {
    await assertFails(getDocs(collection(carol(), "groups")));
  });
});

describe("atac 2: afegir-se a un grup sense codi", () => {
  it("no es pot afegir a memberIds amb arrayUnion", async () => {
    await assertFails(
      updateDoc(doc(mallory(), "groups/gA"), { memberIds: arrayUnion("mallory") })
    );
  });

  it("no es pot reescriure memberIds amb la llista completa + ell", async () => {
    await assertFails(
      updateDoc(doc(mallory(), "groups/gA"), {
        memberIds: ["alice", "bob", "mallory"],
      })
    );
  });

  it("no es pot sobreescriure el grup sencer", async () => {
    await assertFails(
      setDoc(doc(mallory(), "groups/gA"), {
        id: "gA",
        name: "Llar A",
        memberIds: ["mallory"],
        ownerId: "mallory",
        inviteCode: "AAAAAA",
      })
    );
  });
});

describe("atac 3: llegir o llistar perfils d'usuari", () => {
  it("no es poden llistar tots els usuaris", async () => {
    await assertFails(getDocs(collection(mallory(), "users")));
  });

  it("no es pot llegir el perfil d'algú d'un altre grup", async () => {
    await assertFails(getDoc(doc(mallory(), "users/alice")));
  });

  it("no es pot fer una consulta whereIn d'ids d'usuari", async () => {
    await assertFails(
      getDocs(
        query(collection(alice(), "users"), where(documentId(), "in", ["alice", "bob"]))
      )
    );
  });

  it("apuntar el propi currentGroupId al grup de la víctima no dona accés als perfils", async () => {
    // El propi perfil sí que el pot escriure (és legítim)...
    await assertSucceeds(
      updateDoc(doc(mallory(), "users/mallory"), { currentGroupId: "gA" })
    );
    // ...però no el converteix en membre de gA.
    await assertFails(getDoc(doc(mallory(), "users/alice")));
    await assertFails(getDoc(doc(mallory(), "users/bob")));
    // I tampoc li obre el grup ni les seves dades.
    await assertFails(getDoc(doc(mallory(), "groups/gA")));
    await assertFails(getDoc(doc(mallory(), "transactions/transactionsA")));
  });

  it("no es pot escriure el perfil d'un altre", async () => {
    await assertFails(
      updateDoc(doc(mallory(), "users/alice"), { currentGroupId: "gB" })
    );
  });
});

describe("atac 4: moure o injectar dades d'una llar a una altra", () => {
  for (const col of ROOT_COLLECTIONS) {
    it(`${col}: un membre no pot canviar el groupId (moure a una altra llar)`, async () => {
      await assertFails(updateDoc(doc(alice(), `${col}/${col}A`), { groupId: "gB" }));
    });

    it(`${col}: un set sencer amb un altre groupId també queda bloquejat`, async () => {
      await assertFails(
        setDoc(doc(alice(), `${col}/${col}A`), {
          groupId: "gB",
          amount: 10,
          categoryId: "cat1",
          categoryName: "Casa",
        })
      );
    });

    it(`${col}: no es pot crear un document en una llar aliena`, async () => {
      await assertFails(
        setDoc(doc(mallory(), `${col}/injectat`), { groupId: "gA", amount: 999 })
      );
    });

    it(`${col}: no es pot llegir, editar ni esborrar un document d'una llar aliena`, async () => {
      await assertFails(getDoc(doc(mallory(), `${col}/${col}A`)));
      await assertFails(updateDoc(doc(mallory(), `${col}/${col}A`), { amount: 0 }));
      await assertFails(deleteDoc(doc(mallory(), `${col}/${col}A`)));
    });
  }

  it("no es poden llegir les subcol·leccions d'una llar aliena", async () => {
    await assertFails(getDocs(collection(mallory(), "groups/gA/categories")));
  });
});

describe("atac 5: un membre que no és owner canvia camps sensibles del grup", () => {
  it("no pot afegir membres", async () => {
    await assertFails(
      updateDoc(doc(bob(), "groups/gA"), { memberIds: arrayUnion("mallory") })
    );
  });

  it("no pot treure altres membres", async () => {
    await assertFails(
      updateDoc(doc(bob(), "groups/gA"), { memberIds: arrayRemove("alice") })
    );
  });

  it("no es pot fer owner", async () => {
    await assertFails(updateDoc(doc(bob(), "groups/gA"), { ownerId: "bob" }));
  });

  it("no pot canviar el codi d'invitació", async () => {
    await assertFails(updateDoc(doc(bob(), "groups/gA"), { inviteCode: "ZZZZZZ" }));
  });

  it("no pot sortir i alhora canviar un altre camp sensible", async () => {
    await assertFails(
      updateDoc(doc(bob(), "groups/gA"), {
        memberIds: ["alice"],
        inviteCode: "ZZZZZZ",
      })
    );
  });

  it("l'owner no pot sortir mentre hi hagi altres membres", async () => {
    await assertFails(
      updateDoc(doc(alice(), "groups/gA"), { memberIds: arrayRemove("alice") })
    );
  });

  it("l'owner no pot posar un codi amb format invàlid", async () => {
    await assertFails(updateDoc(doc(alice(), "groups/gA"), { inviteCode: "abc" }));
  });
});

describe("atac 5b: crear grups amb dades falses", () => {
  const base = { id: "gX", name: "Llar X", totalAssets: 0 };

  it("no es pot crear un grup amb un altre owner", async () => {
    await assertFails(
      setDoc(doc(mallory(), "groups/gX"), {
        ...base,
        memberIds: ["mallory"],
        ownerId: "alice",
        inviteCode: "XXXXXX",
      })
    );
  });

  it("no es pot crear un grup amb altres membres", async () => {
    await assertFails(
      setDoc(doc(mallory(), "groups/gX"), {
        ...base,
        memberIds: ["mallory", "alice"],
        ownerId: "mallory",
        inviteCode: "XXXXXX",
      })
    );
  });

  for (const inviteCode of ["abc123", "ABC12", "ABC1234", "ABC-12", 123456, null]) {
    it(`no es pot crear un grup amb inviteCode invàlid (${JSON.stringify(inviteCode)})`, async () => {
      await assertFails(
        setDoc(doc(mallory(), "groups/gX"), {
          ...base,
          memberIds: ["mallory"],
          ownerId: "mallory",
          inviteCode,
        })
      );
    });
  }

  it("un usuari no autenticat no pot crear res", async () => {
    const anon = testEnv.unauthenticatedContext().firestore() as unknown as Firestore;
    await assertFails(
      setDoc(doc(anon, "groups/gX"), {
        ...base,
        memberIds: [],
        ownerId: "",
        inviteCode: "XXXXXX",
      })
    );
  });
});

// ---------------------------------------------------------------------------
// FLUXOS LEGÍTIMS: tots han de FUNCIONAR
// ---------------------------------------------------------------------------

describe("legítim: crear un grup", () => {
  it("una usuària sense grup crea el seu grup i el pot llegir", async () => {
    await assertSucceeds(
      setDoc(doc(carol(), "groups/gC"), {
        id: "gC",
        name: "Llar C",
        memberIds: ["carol"],
        ownerId: "carol",
        inviteCode: "CCCC12",
        totalAssets: 0,
      })
    );
    await assertSucceeds(
      updateDoc(doc(carol(), "users/carol"), { currentGroupId: "gC" })
    );
    await assertSucceeds(getDoc(doc(carol(), "groups/gC")));
    await assertSucceeds(
      setDoc(doc(carol(), "transactions/txC"), { groupId: "gC", amount: 5 })
    );
  });
});

describe("legítim: unir-se amb codi via joinGroupWithCode", () => {
  it("amb el codi correcte entra al grup, i després hi pot llegir i escriure", async () => {
    // Abans: carol no veu res de gA.
    await assertFails(getDoc(doc(carol(), "groups/gA")));

    // Accepta minúscules i espais, com si s'haguessin escrit a mà.
    const result = await joinGroupWithCodeImpl(adminDb(), "carol", "  aaaaaa ");
    expect(result).toEqual({ groupId: "gA", groupName: "Llar A" });

    const group = await adminDb().doc("groups/gA").get();
    expect(group.get("memberIds")).toEqual(["alice", "bob", "carol"]);
    const profile = await adminDb().doc("users/carol").get();
    expect(profile.get("currentGroupId")).toBe("gA");

    // Després: és membre de ple dret.
    await assertSucceeds(getDoc(doc(carol(), "groups/gA")));
    await assertSucceeds(getDoc(doc(carol(), "transactions/transactionsA")));
    await assertSucceeds(
      setDoc(doc(carol(), "transactions/txCarol"), { groupId: "gA", amount: 7 })
    );
    await assertSucceeds(getDoc(doc(carol(), "users/alice")));
    await assertSucceeds(getDoc(doc(alice(), "users/carol")));
  });

  it("tornar-s'hi a unir no duplica el membre", async () => {
    await joinGroupWithCodeImpl(adminDb(), "carol", "AAAAAA");
    await joinGroupWithCodeImpl(adminDb(), "carol", "AAAAAA");
    const group = await adminDb().doc("groups/gA").get();
    expect(group.get("memberIds")).toEqual(["alice", "bob", "carol"]);
  });

  it("un codi inexistent dona un error clar i no toca res", async () => {
    await expect(joinGroupWithCodeImpl(adminDb(), "carol", "ZZZZZZ")).rejects.toMatchObject({
      code: "not-found",
      message: "No hi ha cap grup amb aquest codi d'invitació.",
    });
    const profile = await adminDb().doc("users/carol").get();
    expect(profile.get("currentGroupId")).toBeNull();
  });

  it("un codi amb format invàlid dona un error clar", async () => {
    for (const code of ["", "ABC", "ABC-12", undefined, 123456]) {
      await expect(joinGroupWithCodeImpl(adminDb(), "carol", code)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    }
  });

  it("un codi duplicat entre dues llars no uneix ningú", async () => {
    await adminDb().doc("groups/gB").update({ inviteCode: "AAAAAA" });
    await expect(joinGroupWithCodeImpl(adminDb(), "carol", "AAAAAA")).rejects.toMatchObject({
      code: "failed-precondition",
    });
    const group = await adminDb().doc("groups/gA").get();
    expect(group.get("memberIds")).toEqual(["alice", "bob"]);
  });
});

describe("legítim: llegir i escriure dades del grup propi", () => {
  for (const col of ROOT_COLLECTIONS) {
    it(`${col}: CRUD complet d'un membre`, async () => {
      await assertSucceeds(getDoc(doc(bob(), `${col}/${col}A`)));
      await assertSucceeds(
        getDocs(query(collection(bob(), col), where("groupId", "==", "gA")))
      );
      // Actualització parcial (no envia groupId)
      await assertSucceeds(updateDoc(doc(bob(), `${col}/${col}A`), { amount: 20 }));
      // Reescriptura sencera amb el mateix groupId (com fa transactionToFirestoreMap)
      await assertSucceeds(
        setDoc(doc(bob(), `${col}/${col}A`), {
          groupId: "gA",
          amount: 30,
          categoryId: "cat1",
          categoryName: "Casa",
        })
      );
      await assertSucceeds(
        setDoc(doc(bob(), `${col}/nou`), { groupId: "gA", amount: 1 })
      );
      await assertSucceeds(deleteDoc(doc(bob(), `${col}/nou`)));
    });
  }

  it("moure una subcategoria: actualització en lot de categoryId/categoryName dels moviments", async () => {
    const db = alice();
    const batch = writeBatch(db);
    batch.update(doc(db, "transactions/transactionsA"), {
      categoryId: "cat2",
      categoryName: "Oci",
    });
    await assertSucceeds(batch.commit());
  });

  it("reordenar i editar categories del grup", async () => {
    const db = bob();
    const batch = writeBatch(db);
    batch.update(doc(db, "groups/gA/categories/cat1"), { order: 1 });
    batch.update(doc(db, "groups/gA/categories/cat2"), { order: 0 });
    await assertSucceeds(batch.commit());
    await assertSucceeds(getDocs(collection(db, "groups/gA/categories")));
  });

  it("subcol·leccions del grup (traspassos, actius, pressupostos…)", async () => {
    for (const sub of ["transfers", "assets", "debt_accounts", "budget_entries", "cycle_reports"]) {
      await assertSucceeds(setDoc(doc(bob(), `groups/gA/${sub}/x`), { amount: 1 }));
      await assertSucceeds(getDoc(doc(bob(), `groups/gA/${sub}/x`)));
    }
  });
});

describe("legítim: perfils i gestió del grup", () => {
  it("cadascú llegeix i escriu el seu perfil", async () => {
    await assertSucceeds(getDoc(doc(carol(), "users/carol")));
    await assertSucceeds(
      setDoc(doc(alice(), "users/alice"), { name: "Alícia" }, { merge: true })
    );
  });

  it("es poden llegir els perfils dels companys de grup (selector de pagador)", async () => {
    await assertSucceeds(getDoc(doc(alice(), "users/bob")));
    await assertSucceeds(getDoc(doc(bob(), "users/alice")));
  });

  it("un membre llegeix el grup i en canvia camps no sensibles", async () => {
    await assertSucceeds(getDoc(doc(bob(), "groups/gA")));
    await assertSucceeds(
      updateDoc(doc(bob(), "groups/gA"), { name: "Casa nostra", totalAssets: 1000 })
    );
  });

  it("l'owner pot canviar el codi i gestionar membres", async () => {
    await assertSucceeds(updateDoc(doc(alice(), "groups/gA"), { inviteCode: "NOU123" }));
    await assertSucceeds(
      updateDoc(doc(alice(), "groups/gA"), { memberIds: arrayRemove("bob") })
    );
  });

  it("l'owner pot traspassar la propietat a un altre membre", async () => {
    await assertSucceeds(updateDoc(doc(alice(), "groups/gA"), { ownerId: "bob" }));
  });

  it("sortir del grup tal com ho fa l'app: lot amb memberIds i currentGroupId", async () => {
    const db = bob();
    const batch = writeBatch(db);
    batch.update(doc(db, "groups/gA"), { memberIds: arrayRemove("bob") });
    batch.update(doc(db, "users/bob"), { currentGroupId: null });
    await assertSucceeds(batch.commit());
  });

  it("l'owner treu un membre; el tret perd l'accés però pot buidar el seu grup actual", async () => {
    await assertSucceeds(
      updateDoc(doc(alice(), "groups/gA"), { memberIds: arrayRemove("bob") })
    );
    // Això és el que fa fallar el listener de l'app (GroupAccessGuard)...
    await assertFails(getDoc(doc(bob(), "groups/gA")));
    await assertFails(getDoc(doc(bob(), "users/alice")));
    // ...i el que fa després per tornar a la pantalla de crear/unir-se.
    await assertSucceeds(updateDoc(doc(bob(), "users/bob"), { currentGroupId: null }));
  });

  it("l'owner pot treure un uid sense perfil (compte esborrat)", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore() as unknown as Firestore, "groups/gA"), {
        memberIds: arrayUnion("orfe"),
      });
    });
    // El selector llegeix el perfil inexistent sense error de permisos.
    await assertSucceeds(getDoc(doc(alice(), "users/orfe")));
    await assertSucceeds(
      updateDoc(doc(alice(), "groups/gA"), { memberIds: arrayRemove("orfe") })
    );
  });

  it("després de traspassar la propietat, l'antic owner ja pot sortir", async () => {
    await assertSucceeds(updateDoc(doc(alice(), "groups/gA"), { ownerId: "bob" }));
    await assertSucceeds(
      updateDoc(doc(alice(), "groups/gA"), { memberIds: arrayRemove("alice") })
    );
    // I el nou owner és qui gestiona el codi.
    await assertSucceeds(updateDoc(doc(bob(), "groups/gA"), { inviteCode: "BOB123" }));
  });

  it("l'antic owner ja no pot gestionar membres després del traspàs", async () => {
    await assertSucceeds(updateDoc(doc(alice(), "groups/gA"), { ownerId: "bob" }));
    await assertFails(
      updateDoc(doc(alice(), "groups/gA"), { memberIds: arrayRemove("bob") })
    );
    await assertFails(updateDoc(doc(alice(), "groups/gA"), { inviteCode: "ALI123" }));
  });

  it("un membre que no és owner pot sortir del grup", async () => {
    await assertSucceeds(
      updateDoc(doc(bob(), "groups/gA"), { memberIds: arrayRemove("bob") })
    );
    // I un cop fora, ja no hi té accés.
    await assertFails(getDoc(doc(bob(), "groups/gA")));
    await assertFails(getDoc(doc(bob(), "transactions/transactionsA")));
  });
});
