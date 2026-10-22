import { type Meta, type StoryObj } from "@storybook/react-vite";

import { make } from "./LoadingFullscreen.gen";

const meta: Meta<typeof make> = {
  title: "Components/LoadingFullscreen",
  component: make,
  parameters: {
    layout: "fullscreen",
  },
};

export default meta;

export const Basic: StoryObj<typeof make> = {};
