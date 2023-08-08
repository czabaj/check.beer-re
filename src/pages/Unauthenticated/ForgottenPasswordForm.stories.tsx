import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./ForgottenPasswordForm.gen";

const ForgottenPasswordForm = make;

const meta: Meta<typeof ForgottenPasswordForm> = {
  title: "Pages/Unauthenticated/ForgottenPasswordForm",
  component: ForgottenPasswordForm,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    isOnline: { control: { type: "boolean" } },
    onGoBack: { action: `onGoBack` },
    onSubmit: { action: `onSubmit` },
  },
};

export default meta;

export const Basic: StoryObj<typeof ForgottenPasswordForm> = {};
