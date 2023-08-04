import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./Homepage.gen";

const Homepage = make;

const meta: Meta<typeof Homepage> = {
  title: "Pages/Homepage",
  component: Homepage,
  parameters: {
    actions: { argTypesRegex: "^on[A-Z].*" },
    layout: "fullscreen",
  },
};

export default meta;

export const Basic: StoryObj<typeof Homepage> = {};
