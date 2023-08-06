import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./SignUpForm.gen";

const SignUpForm = make;

const meta: Meta<typeof SignUpForm> = {
  title: "Pages/SignUpForm",
  component: SignUpForm,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    onGoBack: { action: `onGoBack` },
    onSubmit: { action: `onSubmit` },
  },
};

export default meta;

export const Basic: StoryObj<typeof SignUpForm> = {};
