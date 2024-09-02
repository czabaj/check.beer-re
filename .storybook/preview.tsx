import '@oddbird/popover-polyfill';
import type { Preview } from "@storybook/react";
import React from "react";
import { IntlProvider } from "react-intl";

import "../src/styles/index.css";

const preview: Preview = {
  decorators: [
    (Story) => (
      <IntlProvider
        locale="cs"
        onError={(err) => {
          err.code !== "MISSING_TRANSLATION" && console.error(err);
        }}
      >
        <Story />
      </IntlProvider>
    ),
  ],
  parameters: {
    actions: { argTypesRegex: "^on[A-Z].*" },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/,
      },
    },
  },
};

export default preview;
