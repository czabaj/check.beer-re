import { action } from "@storybook/addon-actions";
import { type Meta, type StoryObj } from "@storybook/react";

import { Pure } from "./Unauthenticated.gen";

const meta: Meta<typeof Pure.make> = {
  title: "Pages/Unauthenticated",
  component: Pure.make,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    initialEmail: { control: `text` },
    onBackToForm: { action: `onBackToForm` },
    onGoogleAuth: { action: `onGoogleAuth` },
    onPasswordAuth: { action: `onPasswordAuth` },
    signInEmailSent: { control: `text` },
  },
};

export default meta;

export const Basic: StoryObj<typeof Pure.make> = {};

export const EmailSent: StoryObj<typeof Pure.make> = {
  args: {
    signInEmailSent: `example@example.com`,
  },
};
