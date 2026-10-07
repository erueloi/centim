import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    // Tots els tests comparteixen el mateix emulador de Firestore.
    fileParallelism: false,
    testTimeout: 20000,
    hookTimeout: 30000,
  },
});
