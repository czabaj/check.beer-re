import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./ForgottenPasswordForm.gen";

const ForgottenPasswordForm = make;

const meta: Meta<typeof ForgottenPasswordForm> = {
  title: "Pages/ForgottenPasswordForm",
  component: ForgottenPasswordForm,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    onGoBack: { action: `onGoBack` },
    onSubmit: { action: `onSubmit` },
  },
};

export default meta;

export const Basic: StoryObj<typeof ForgottenPasswordForm> = {};
