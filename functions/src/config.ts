import { defineSecret, defineString } from "firebase-functions/params";

/** Regió europea (RGPD + latència). Totes les Functions es despleguen aquí. */
export const REGION = "europe-west1";

/**
 * Redirect per defecte (producció web). L'app pot demanar-ne una altra (p.ex.
 * http://localhost:5000/bank-callback en dev), sempre validada contra allowlist.
 */
export const REDIRECT_URL = "https://centim-162bd.web.app/bank-callback";

/**
 * Valida el redirect_url demanat per l'app per evitar open-redirects: només
 * el domini de hosting o localhost, i sempre path /bank-callback. Retorna el
 * default si no se'n demana cap; llança si se'n demana un de no permès.
 */
export function resolveRedirectUrl(requested?: string): string {
  if (!requested) return REDIRECT_URL;
  try {
    const u = new URL(requested);
    const hostOk =
      u.hostname === "centim-162bd.web.app" ||
      u.hostname === "localhost" ||
      u.hostname === "127.0.0.1";
    const schemeOk =
      u.protocol === "https:" ||
      u.hostname === "localhost" ||
      u.hostname === "127.0.0.1";
    if (hostOk && schemeOk && u.pathname === "/bank-callback") {
      return requested;
    }
  } catch {
    // cau al throw de sota
  }
  throw new Error(`redirect_url no permès: ${requested}`);
}

/**
 * Banc objectiu, parametritzable sense tocar codi:
 *  - Sandbox: ASPSP_NAME = "Mock ASPSP" (CaixaBank no existeix a Sandbox).
 *  - Producció: default "CaixaBank".
 * Es fixa via functions/.env (ASPSP_NAME=Mock ASPSP) o params de desplegament.
 */
export const ASPSP_NAME = defineString("ASPSP_NAME", { default: "CaixaBank" });
export const ASPSP_COUNTRY = defineString("ASPSP_COUNTRY", { default: "ES" });

/** Slug estable per al doc de connexió (p.ex. "Mock ASPSP" -> "mock-aspsp"). */
export const aspspSlug = (name: string): string =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

/** Tipus de PSU per a l'autorització AIS. */
export const PSU_TYPE = "personal";

/**
 * Validesa de consentiment que demanem (dies). El valor real es capa a la
 * validesa màxima que retorna CaixaBank a /aspsps (Redsys sol capar a 90 dies);
 * mai la hardcodegem al body de /auth.
 */
export const REQUESTED_CONSENT_DAYS = 90;

/** Document per usuari on desem l'estat de la connexió bancària d'un banc. */
export const bankConnectionDoc = (uid: string, slug: string) =>
  `users/${uid}/bank_connections/${slug}`;

/**
 * Entorn d'Enable Banking, seleccionable sense tocar codi de negoci via
 * functions/.env (ENABLEBANKING_ENV=production) o params de desplegament.
 * Default "sandbox" per seguretat.
 */
export const ENABLEBANKING_ENV = defineString("ENABLEBANKING_ENV", {
  default: "sandbox",
});

/**
 * Secrets a Google Secret Manager. Es carreguen NOMÉS al servidor; mai a l'app.
 * Dos entorns EN PARAL·LEL (no es toquen entre ells):
 *  - SANDBOX: reutilitza els secrets ja carregats amb els noms originals
 *    (ENABLEBANKING_APP_ID / ENABLEBANKING_PEM) per no haver de re-introduir-los.
 *  - PRODUCCIÓ: secrets nous amb sufix _PROD.
 * Cada secret és la clau privada RS256 (PKCS#8) o l'UUID de l'app (va al `kid`).
 */
export const ENABLEBANKING_APP_ID_SANDBOX = defineSecret("ENABLEBANKING_APP_ID");
export const ENABLEBANKING_PEM_SANDBOX = defineSecret("ENABLEBANKING_PEM");
export const ENABLEBANKING_APP_ID_PROD = defineSecret("ENABLEBANKING_APP_ID_PROD");
export const ENABLEBANKING_PEM_PROD = defineSecret("ENABLEBANKING_PEM_PROD");

/**
 * Tots els secrets EB que cal declarar a `secrets: [...]` de cada Function.
 * (Cal declarar-los tots encara que en runtime només s'usi el joc de l'entorn
 * actiu; per això els 4 han d'existir a Secret Manager abans del deploy.)
 */
export const ALL_EB_SECRETS = [
  ENABLEBANKING_APP_ID_SANDBOX,
  ENABLEBANKING_PEM_SANDBOX,
  ENABLEBANKING_APP_ID_PROD,
  ENABLEBANKING_PEM_PROD,
];

/** Base URL per entorn (avui idèntica; separada per si algun dia divergeix). */
const EB_BASE_URL: Record<string, string> = {
  sandbox: "https://api.enablebanking.com",
  production: "https://api.enablebanking.com",
};

export interface EbCredentials {
  env: "sandbox" | "production";
  appId: string;
  pem: string;
  baseUrl: string;
}

/**
 * Resol el joc de credencials + base URL segons ENABLEBANKING_ENV.
 * Llegir els secrets (.value()) NOMÉS aquí i en runtime.
 */
export function resolveEbCredentials(): EbCredentials {
  const env =
    (ENABLEBANKING_ENV.value() || "sandbox").trim().toLowerCase() ===
    "production"
      ? "production"
      : "sandbox";

  if (env === "production") {
    return {
      env,
      appId: ENABLEBANKING_APP_ID_PROD.value(),
      pem: ENABLEBANKING_PEM_PROD.value(),
      baseUrl: EB_BASE_URL.production,
    };
  }
  return {
    env,
    appId: ENABLEBANKING_APP_ID_SANDBOX.value(),
    pem: ENABLEBANKING_PEM_SANDBOX.value(),
    baseUrl: EB_BASE_URL.sandbox,
  };
}
