import { IntlProvider } from "react-intl";

import "../src/styles/index.css";

/** @type { import('@storybook/react').Preview } */
const preview = {
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
