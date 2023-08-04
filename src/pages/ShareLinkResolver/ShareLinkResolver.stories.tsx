import { action } from "@storybook/addon-actions";
import { type Meta, type StoryObj } from "@storybook/react";

import { Pure } from "./ShareLinkResolver.gen";

const ShareLinkResolver = Pure.make;

const meta: Meta<typeof ShareLinkResolver> = {
  title: "Pages/ShareLinkResolver",
  component: ShareLinkResolver,
  parameters: {
    layout: "fullscreen",
  },
};

export default meta;

export const Basic: StoryObj<typeof ShareLinkResolver> = {
  args: {
    data: [{ role: 10 } as any, { name: "U Suchánků" } as any],
    onAccept: action(`onAccept`),
  },
};

export const Error: StoryObj<typeof ShareLinkResolver> = {};
