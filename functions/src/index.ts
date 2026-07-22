import { initializeApp } from "firebase-admin/app";

// Inicialitza l'SDK d'Admin un sol cop per a totes les Functions.
initializeApp();

export { startBankAuth } from "./startBankAuth.js";
export { finalizeBankSession } from "./finalizeBankSession.js";
