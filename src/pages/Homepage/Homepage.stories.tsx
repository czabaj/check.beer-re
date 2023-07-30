import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./Homepage.gen";

const meta: Meta<typeof make> = {
  title: "Pages/Homepage",
  component: make,
  parameters: {
    layout: "fullscreen",
  },
};

export default meta;

export const Basic: StoryObj<typeof make> = {};
