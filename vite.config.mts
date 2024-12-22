/// <reference types="vitest" />
/// <reference types="vite/client" />

import createReScriptPlugin from "@jihchi/vite-plugin-rescript";
import { sentryVitePlugin } from "@sentry/vite-plugin";
import createReactPlugin from "@vitejs/plugin-react";
import { defineConfig, splitVendorChunkPlugin } from "vite";
import { ViteEjsPlugin } from "vite-plugin-ejs";
import { VitePWA } from "vite-plugin-pwa";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  build: {
    sourcemap: mode === `production`,
  },
  plugins: [
    createReactPlugin(),
    mode !== `test` && createReScriptPlugin(),
    mode === `production` &&
      sentryVitePlugin({
        authToken: process.env.SENTRY_AUTH_TOKEN,
        org: "vaclav",
        project: "check-beer",
      }),
    splitVendorChunkPlugin(),
    ViteEjsPlugin((viteConfig) => ({
      env: {
        mode,
        ...viteConfig.env,
      },
    })),
    VitePWA({
      devOptions: {
        enabled: true,
        type: "module",
      },
      filename: "sw.ts",
      injectManifest: {
        globPatterns: [`**/*.{js,css,html,png,svg}`],
      },
      manifest: {
        name: "Check Beer",
        short_name: "CheckBeer",
        description: "Kamarádské pivní účetnictví",
        theme_color: "#708465",
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
      strategies: `injectManifest`,
      srcDir: "src/serviceWorker",
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
