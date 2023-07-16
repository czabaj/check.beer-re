/// <reference types="vitest" />
/// <reference types="vite/client" />

import { defineConfig } from "vite";
import createReactPlugin from "@vitejs/plugin-react";
import createReScriptPlugin from "@jihchi/vite-plugin-rescript";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [
    createReactPlugin(),
    mode !== `test` && createReScriptPlugin(),
  ].filter(Boolean),
  test: {
    include: [
      //"tests/**/*_test.bs.js",
      "src/**/*.test.ts",
    ],
    globals: true,
    environment: "jsdom",
    setupFiles: "./tests/setup.ts",
  },
}));
