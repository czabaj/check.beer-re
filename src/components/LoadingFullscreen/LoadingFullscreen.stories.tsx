import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./LoadingFullscreen.gen";

const meta: Meta<typeof make> = {
  title: "LoadingFullscreen",
  component: make,
  parameters: {
    layout: "fullscreen",
  },
};

export default meta;

export const Basic: StoryObj<typeof make> = {};
