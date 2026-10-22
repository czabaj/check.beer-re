/// <reference types="vitest/config" />
/// <reference types="vite/client" />

import createReScriptPlugin from "@jihchi/vite-plugin-rescript";
import { sentryVitePlugin } from "@sentry/vite-plugin";
import createReactPlugin from "@vitejs/plugin-react";
import { defineConfig, type Plugin } from "vite";
import { ViteEjsPlugin } from "vite-plugin-ejs";
import { VitePWA } from "vite-plugin-pwa";

// Storybook resolves the config twice with the same plugin instances, the second
// `configResolved` would spawn another `rescript watch` which fails on the lock
const createReScriptPluginOnce = (): Plugin => {
  const plugin = createReScriptPlugin();
  const configResolved = plugin.configResolved;
  if (typeof configResolved !== "function") return plugin;
  let launched = false;
  return {
    ...plugin,
    configResolved(...args) {
      if (launched) return;
      launched = true;
      return configResolved.apply(this, args);
    },
  };
};

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  build: {
    sourcemap: mode === `production`,
  },
  plugins: [
    createReactPlugin(),
    mode !== `test` && createReScriptPluginOnce(),
    mode === `production` &&
      sentryVitePlugin({
        authToken: process.env.SENTRY_AUTH_TOKEN,
        org: "vaclav",
        project: "check-beer",
      }),
    ViteEjsPlugin((viteConfig) => ({
      env: {
        mode,
        ...viteConfig.env,
      },
    })),
    VitePWA({
      devOptions: {
        enabled: true,
        navigateFallback: "index.html",
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
    include: ["src/**/*.test.{js,jsx,ts}"],
    globals: true,
    environment: "jsdom",
    setupFiles: "./tests/setup.ts",
  },
}));
