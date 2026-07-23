import { initializeApp } from "firebase-admin/app";

// Inicialitza l'SDK d'Admin un sol cop per a totes les Functions.
initializeApp();

export { startBankAuth } from "./startBankAuth.js";
export { finalizeBankSession } from "./finalizeBankSession.js";
export { fetchBankTransactions } from "./fetchBankTransactions.js";
export { listBankAccounts } from "./listBankAccounts.js";
export { updateBankAccountConfig } from "./updateBankAccountConfig.js";

// PROBE TEMPORAL (treure després de validar la cadena de producció):
export { probeAccountData } from "./probeAccountData.js";
