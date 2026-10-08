import { generateKeyPairSync, randomBytes } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { vi } from "vitest";

export const PROJECT_ID = "demo-centim";

/** fetch real, abans que cap test el substitueixi pel simulat. */
export const realFetch: typeof fetch = globalThis.fetch.bind(globalThis);

export function adminDb() {
  if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
  return getFirestore();
}

/** Buida l'emulador de Firestore (cada fitxer de tests comparteix l'emulador). */
export async function clearFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) throw new Error("Cal executar els tests amb l'emulador (npm run test:rules).");
  await realFetch(
    `http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    { method: "DELETE" }
  );
}

/** Petició callable mínima, com la que construeix firebase-functions. */
export function callAs(uid: string, data: Record<string, unknown> = {}) {
  return {
    data,
    auth: { uid, token: { uid } },
    rawRequest: { headers: { "user-agent": "vitest" }, ip: "127.0.0.1" },
    acceptsStreaming: false,
  } as unknown as CallableRequest;
}

/** Clau RSA de prova en PEM (PKCS#8 per defecte). */
export function generatePem(type: "pkcs8" | "pkcs1" = "pkcs8"): string {
  const { privateKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    publicKeyEncoding: { type: "spki", format: "pem" },
    privateKeyEncoding: { type, format: "pem" },
  });
  return privateKey;
}

/** Fragments interiors d'una clau PEM: no han d'aparèixer enlloc. */
export function pemFragments(pem: string): string[] {
  return pem
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length >= 40 && !line.startsWith("-----"));
}

export function testKeyring(): string {
  return JSON.stringify({
    current: "v1",
    keys: { v1: randomBytes(32).toString("base64") },
  });
}

export interface EbCall {
  method: string;
  path: string;
  query: URLSearchParams;
  /** `kid` del JWT: identifica amb quina aplicació s'ha signat la crida. */
  kid: string | null;
  body: unknown;
}

export type EbResponse = { status?: number; body?: unknown };

function kidOf(authorization: string | null): string | null {
  const token = authorization?.replace(/^Bearer\s+/i, "") ?? "";
  const header = token.split(".")[0];
  if (!header) return null;
  try {
    return JSON.parse(Buffer.from(header, "base64url").toString("utf8")).kid ?? null;
  } catch {
    return null;
  }
}

/**
 * Substitueix fetch per un Enable Banking simulat. Cap test arriba a la xarxa.
 * `handler` rep cada crida i en decideix la resposta.
 */
export function mockEnableBanking(handler: (call: EbCall) => EbResponse) {
  const calls: EbCall[] = [];
  const spy = vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
    const url = new URL(input instanceof Request ? input.url : String(input));
    const call: EbCall = {
      method: init?.method ?? "GET",
      path: url.pathname,
      query: url.searchParams,
      kid: kidOf(new Headers(init?.headers).get("Authorization")),
      body: typeof init?.body === "string" ? JSON.parse(init.body) : undefined,
    };
    calls.push(call);
    const response = handler(call);
    const status = response.status ?? 200;
    return new Response(
      response.body === undefined ? null : JSON.stringify(response.body),
      { status }
    );
  });
  return { calls, spy };
}

export const PRODUCTION_CALLBACK = "https://centim-162bd.web.app/bank-callback";

export const MOCK_ASPSPS = [
  {
    name: "CaixaBank",
    country: "ES",
    psu_types: ["personal"],
    maximum_consent_validity: 15552000,
  },
  {
    name: "Mock ASPSP",
    country: "ES",
    logo: "https://enablebanking.com/brands/mock.png",
    psu_types: ["business", "personal"],
    maximum_consent_validity: 15552000,
  },
  {
    name: "BBVA",
    country: "ES",
    logo: "https://enablebanking.com/brands/bbva.png",
    psu_types: ["personal"],
    maximum_consent_validity: 7776000,
    required_psu_headers: ["psu-ip-address"],
  },
  {
    name: "Banc Només Empreses",
    country: "ES",
    psu_types: ["business"],
    maximum_consent_validity: 7776000,
  },
];

/** Respostes per defecte d'un Enable Banking que tot ho accepta. */
export function defaultEbHandler(overrides: Partial<Record<string, EbResponse>> = {}) {
  return (call: EbCall): EbResponse => {
    const key = `${call.method} ${call.path.replace(/\/sessions\/.+/, "/sessions/:id")}`;
    if (overrides[key]) return overrides[key]!;
    switch (key) {
      case "GET /application":
        return {
          body: {
            name: "Cèntim Llar",
            environment: "PRODUCTION",
            active: true,
            redirect_urls: [PRODUCTION_CALLBACK],
          },
        };
      case "GET /aspsps":
        return { body: { aspsps: MOCK_ASPSPS } };
      case "POST /auth":
        return { body: { url: "https://tilisy.enablebanking.com/auth?x=1" } };
      case "POST /sessions":
        return {
          body: {
            session_id: "sess-new",
            accounts: [
              {
                uid: "acc-1",
                identification_hash: "hash-1",
                account_id: { iban: "ES9121000418450200051332" },
                name: "Compte nou",
                currency: "EUR",
              },
            ],
            access: { valid_until: "2027-04-01T00:00:00Z" },
          },
        };
      case "DELETE /sessions/:id":
        return { status: 200, body: {} };
      default:
        return { status: 404, body: { message: "no simulat" } };
    }
  };
}
