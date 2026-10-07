import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

/** Comprova que la crida callable ve d'un usuari autenticat i retorna el seu uid. */
export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Cal haver iniciat sessió.");
  }
  return uid;
}
