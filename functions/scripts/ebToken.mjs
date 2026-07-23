// Retorna un ID token de Firebase vàlid per als scripts de prova.
// Preferència: si hi ha credencials (EB_WEB_API_KEY + EB_EMAIL + EB_PASSWORD),
// en genera un de FRESC a cada crida (els ID token caduquen a 1 hora, així
// s'evita el 401 "Unauthenticated"). Si no, cau a EB_ID_TOKEN si el tens posat.

export async function getIdToken() {
  const apiKey = process.env.EB_WEB_API_KEY;
  const email = process.env.EB_EMAIL;
  const password = process.env.EB_PASSWORD;

  if (apiKey && email && password) {
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      }
    );
    const body = await res.json();
    if (!res.ok) {
      throw new Error("Login fallit: " + (body.error?.message ?? res.status));
    }
    return body.idToken;
  }

  if (process.env.EB_ID_TOKEN) return process.env.EB_ID_TOKEN;

  throw new Error(
    "Configura EB_WEB_API_KEY + EB_EMAIL + EB_PASSWORD (recomanat, token sempre fresc) o EB_ID_TOKEN."
  );
}
