/**
 * Capçaleres PSU (PSD2). Marquen una petició com a "amb el client present".
 *
 * Per què importa: els bancs limiten fortament l'accés AIS *desatès* (~4
 * consultes per compte i dia). Les nostres sincronitzacions sempre les dispara
 * l'usuari des de l'app, o sigui que SÓN ateses: enviant la seva IP ho fem
 * explícit i el banc no ens hauria d'aplicar la quota d'accés desatès.
 *
 * Regla d'Enable Banking: "Either all required PSU headers or none of PSU
 * headers are to be provided" — si no podem cobrir totes les requerides, no
 * n'enviem cap (si no, error PSU_HEADER_NOT_PROVIDED).
 */

/** Extreu la IP real del client de la petició callable (darrere de proxy). */
export function clientIpOf(rawRequest: unknown): string | null {
  const req = rawRequest as
    | { headers?: Record<string, unknown>; ip?: unknown }
    | undefined;
  const xff = req?.headers?.["x-forwarded-for"];
  if (typeof xff === "string" && xff.trim()) {
    return xff.split(",")[0].trim();
  }
  if (Array.isArray(xff) && xff.length > 0) {
    return String(xff[0]).split(",")[0].trim();
  }
  const ip = req?.ip;
  return typeof ip === "string" && ip.trim() ? ip.trim() : null;
}

/**
 * Construeix les capçaleres PSU a enviar.
 * @param requiredPsuHeaders llista que exigeix l'ASPSP (de /aspsps); si és
 *   buida o desconeguda, enviem el mínim que aixeca el límit d'accés desatès.
 */
export function buildPsuHeaders(
  rawRequest: unknown,
  requiredPsuHeaders: string[] | null
): Record<string, string> {
  const available: Record<string, string> = {};

  const ip = clientIpOf(rawRequest);
  if (ip) available["Psu-Ip-Address"] = ip;

  const req = rawRequest as { headers?: Record<string, unknown> } | undefined;
  const ua = req?.headers?.["user-agent"];
  if (typeof ua === "string" && ua.trim()) {
    available["Psu-User-Agent"] = ua.trim();
  }

  if (!requiredPsuHeaders || requiredPsuHeaders.length === 0) {
    return available;
  }

  // Requisits coneguts: o les cobrim totes, o no n'enviem cap.
  const out: Record<string, string> = {};
  for (const name of requiredPsuHeaders) {
    const match = Object.keys(available).find(
      (k) => k.toLowerCase() === name.toLowerCase()
    );
    if (!match) return {};
    out[match] = available[match];
  }
  return out;
}
