import { defineSecret, defineString } from "firebase-functions/params";

/** Regió europea (RGPD + latència). Totes les Functions es despleguen aquí. */
export const REGION = "europe-west1";

/**
 * Redirect whitelistada a Enable Banking. Pàgina de Firebase Hosting que
 * (Fase 2) capta ?code=&state= i fa deep-link de tornada a l'app.
 */
export const REDIRECT_URL = "https://centim-162bd.web.app/bank-callback";

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
 * Secrets a Google Secret Manager. Es carreguen NOMÉS al servidor; mai a l'app.
 *  - ENABLEBANKING_PEM: clau privada RS256 (PKCS#8) del TPP.
 *  - ENABLEBANKING_APP_ID: UUID de l'aplicació (va al `kid` del JWT).
 */
export const ENABLEBANKING_PEM = defineSecret("ENABLEBANKING_PEM");
export const ENABLEBANKING_APP_ID = defineSecret("ENABLEBANKING_APP_ID");
