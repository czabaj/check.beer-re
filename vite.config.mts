/// <reference types="vitest" />
/// <reference types="vite/client" />

import createReScriptPlugin from "@jihchi/vite-plugin-rescript";
import createReactPlugin from "@vitejs/plugin-react";
import { defineConfig, splitVendorChunkPlugin } from "vite";
import { VitePWA } from "vite-plugin-pwa";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [
    createReactPlugin(),
    mode !== `test` && createReScriptPlugin(),
    splitVendorChunkPlugin(),
    VitePWA({
      manifest: {
        name: "Check Beer",
        short_name: "CheckBeer",
        description: "Kamarádské pivní účetnictví",
        theme_color: "#edeeed",
        icons: [
          {
            src: "pwa-192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "pwa-512.png",
            sizes: "512x512",
            type: "image/png",
          },
        ],
      },
      registerType: `autoUpdate`,
      workbox: {
        globPatterns: [`**/*.{js,css,html,png,svg}`],
      },
    }),
  ].filter(Boolean),
  server: {
    host: `0.0.0.0`,
  },
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
