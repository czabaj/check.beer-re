import type { StorybookConfig } from "@storybook/react-vite";
import type { PluginOption } from "vite";

const isPwaPlugin = (plugin: PluginOption) =>
  Boolean(
    plugin &&
      "name" in plugin &&
      plugin.name.startsWith("vite-plugin-pwa"),
  );

const config: StorybookConfig = {
  addons: ["@storybook/addon-links", "@storybook/addon-docs"],
  framework: {
    name: "@storybook/react-vite",
    options: {},
  },
  stories: ["../src/**/*.mdx", "../src/**/*.stories.@(js|jsx|ts|tsx)"],
  viteFinal(config) {
    // the app service worker has no use in Storybook and its precache chokes on
    // the Storybook manager bundle
    return {
      ...config,
      plugins: config.plugins?.flat(Infinity).filter((p) => !isPwaPlugin(p)),
    };
  },
};

export default config;
