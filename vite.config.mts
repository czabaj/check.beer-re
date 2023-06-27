/// <reference types="vitest" />
/// <reference types="vite/client" />

import { defineConfig } from "vite";
import svgrPlugin from "vite-plugin-svgr";
import createReactPlugin from "@vitejs/plugin-react";
import createReScriptPlugin from "@jihchi/vite-plugin-rescript";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [createReactPlugin(), createReScriptPlugin(), svgrPlugin()],
  test: {
    include: ["tests/**/*_test.bs.js"],
    globals: true,
    environment: "jsdom",
    setupFiles: "./tests/setup.ts",
  },
});
