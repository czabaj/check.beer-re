import { action } from "@storybook/addon-actions";
import { type Meta, type StoryObj } from "@storybook/react";

import { Pure } from "./ShareLinkResolver.gen";

const meta: Meta<typeof Pure.make> = {
  title: "Pages/ShareLinkResolver",
  component: Pure.make,
  parameters: {
    layout: "fullscreen",
  },
};

export default meta;

export const Basic: StoryObj<typeof Pure.make> = {
  args: {
    data: [{ role: 10 } as any, { name: "U Suchánků" } as any],
    onAccept: action(`onAccept`),
  },
};

export const Error: StoryObj<typeof Pure.make> = {};
