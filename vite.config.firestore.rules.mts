/// <reference types="vitest/config" />
/// <reference types="vite/client" />

import { defineConfig } from "vite";

// https://vitejs.dev/config/
export default defineConfig({
  test: {
    include: ["firestore.rules.test.ts"],
    globals: true,
  },
});
