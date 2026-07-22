// Obté un ID token de Firebase d'un usuari email/contrasenya, via la REST
// signInWithPassword. Serveix per provar les callables des de scripts.
//
// Ús (des de functions/):
//   $env:EB_WEB_API_KEY="<Web API Key>"
//   $env:EB_EMAIL="test@exemple.com"
//   $env:EB_PASSWORD="la-contrasenya"
//   node scripts/get_id_token.mjs
//
// Imprimeix NOMÉS l'idToken, així el pots capturar directament:
//   $env:EB_ID_TOKEN = (node scripts/get_id_token.mjs)

const apiKey = process.env.EB_WEB_API_KEY;
const email = process.env.EB_EMAIL;
const password = process.env.EB_PASSWORD;

if (!apiKey || !email || !password) {
  console.error(
    "✗ Falten variables: EB_WEB_API_KEY, EB_EMAIL, EB_PASSWORD."
  );
  process.exit(1);
}

const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;

const res = await fetch(url, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email, password, returnSecureToken: true }),
});

const body = await res.json();
if (!res.ok) {
  console.error(`✗ Login ha fallat: ${body.error?.message ?? res.status}`);
  process.exit(1);
}

// Només l'idToken a stdout (perquè es pugui capturar en una variable).
process.stdout.write(body.idToken);
