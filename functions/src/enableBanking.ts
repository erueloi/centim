import { importPKCS8, SignJWT, type KeyLike } from "jose";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

/** Base URL per defecte (Sandbox i Producció comparteixen host avui). */
export const ENABLE_BANKING_BASE = "https://api.enablebanking.com";

/**
 * Construeix un JWT curt (RS256) per autenticar-nos davant d'Enable Banking.
 *
 * Matisos aplicats:
 *  - (a) la clau .pem s'importa com a KeyLike amb importPKCS8 abans de signar;
 *        mai passem el text pla del PEM al signador.
 *  - (b) exp = iat + 5 min; se'n genera un de NOU a cada crida (no es cacheja);
 *        el `kid` va al HEADER protegit, no al payload.
 */
export async function buildEnableBankingJwt(
  appId: string,
  pem: string
): Promise<string> {
  if (pem.includes("BEGIN RSA PRIVATE KEY")) {
    // Clau en format PKCS#1; Enable Banking genera PKCS#8 (BEGIN PRIVATE KEY).
    throw new HttpsError(
      "failed-precondition",
      "La clau privada ha d'estar en format PKCS#8 (-----BEGIN PRIVATE KEY-----)."
    );
  }

  let key: KeyLike;
  try {
    key = await importPKCS8(pem, "RS256");
  } catch (e) {
    // No fem log del contingut de la clau ni de l'error cru per no filtrar-la.
    logger.error("No s'ha pogut importar la clau privada d'Enable Banking.");
    throw new HttpsError(
      "internal",
      "Configuració de credencials d'Enable Banking invàlida."
    );
  }

  const nowSeconds = Math.floor(Date.now() / 1000);

  return await new SignJWT({})
    .setProtectedHeader({ alg: "RS256", kid: appId, typ: "JWT" })
    .setIssuer("enablebanking.com")
    .setAudience("api.enablebanking.com")
    .setIssuedAt(nowSeconds)
    .setExpirationTime(nowSeconds + 300) // 5 minuts
    .sign(key);
}

/** Opcions per a una crida a l'API d'Enable Banking. */
interface EbRequestOptions {
  method?: "GET" | "POST";
  jwt: string;
  /** Base URL de l'entorn actiu (sandbox/producció). */
  baseUrl?: string;
  query?: Record<string, string>;
  body?: unknown;
  /** Capçaleres addicionals (p.ex. PSU-* per marcar accés amb client present). */
  extraHeaders?: Record<string, string>;
}

/**
 * Crida autenticada a l'API d'Enable Banking.
 * Llança HttpsError en respostes no 2xx SENSE filtrar credencials als logs.
 */
export async function enableBankingFetch<T>(
  path: string,
  opts: EbRequestOptions
): Promise<T> {
  const url = new URL((opts.baseUrl ?? ENABLE_BANKING_BASE) + path);
  if (opts.query) {
    for (const [k, v] of Object.entries(opts.query)) {
      url.searchParams.set(k, v);
    }
  }

  const method = opts.method ?? "GET";

  let response: Response;
  try {
    response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${opts.jwt}`,
        Accept: "application/json",
        ...(opts.body ? { "Content-Type": "application/json" } : {}),
        ...(opts.extraHeaders ?? {}),
      },
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    });
  } catch (e) {
    logger.error("Error de xarxa cridant Enable Banking", {
      path,
      method,
    });
    throw new HttpsError("unavailable", "No s'ha pogut contactar amb el banc.");
  }

  const text = await response.text();
  let parsed: unknown;
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch {
    parsed = { raw: text };
  }

  if (!response.ok) {
    // Log només de metadades no sensibles (mai el body de la resposta,
    // que pot contenir codes/tokens; ni el JWT).
    logger.error("Enable Banking ha retornat error", {
      path,
      method,
      status: response.status,
    });

    // 429 = límit de peticions. Amb bancs reals sol ser el límit PSD2 d'accés
    // sense el client present (4 consultes per compte i dia), no un error nostre.
    if (response.status === 429) {
      // Enable Banking no documenta capçaleres de quota, però si el servidor
      // n'envia cap (Retry-After / *ratelimit*) les registrem i les aprofitem.
      const rateHeaders: Record<string, string> = {};
      response.headers.forEach((v, k) => {
        const lk = k.toLowerCase();
        if (lk === "retry-after" || lk.includes("ratelimit")) {
          rateHeaders[lk] = v;
        }
      });
      logger.warn("Límit de consultes del banc (429)", {
        path,
        rateHeaders,
        hasRateHeaders: Object.keys(rateHeaders).length > 0,
      });

      const retryAfter = rateHeaders["retry-after"];
      const retryHint = retryAfter ? ` Torna-ho a provar d'aquí ${retryAfter}s.` : "";

      throw new HttpsError(
        "resource-exhausted",
        "El banc ha limitat les consultes. La normativa PSD2 permet només unes " +
          "poques sincronitzacions per compte i dia sense tornar a identificar-te." +
          (retryHint || " Torna-ho a provar més tard."),
        { status: 429, path, retryAfter: retryAfter ?? null }
      );
    }

    throw new HttpsError(
      response.status === 401 || response.status === 403
        ? "permission-denied"
        : "internal",
      `Enable Banking error ${response.status}`,
      { status: response.status, path }
    );
  }

  return parsed as T;
}

/** Comprova que la crida callable ve d'un usuari autenticat i retorna el seu uid. */
export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Cal haver iniciat sessió per connectar el banc."
    );
  }
  return uid;
}
