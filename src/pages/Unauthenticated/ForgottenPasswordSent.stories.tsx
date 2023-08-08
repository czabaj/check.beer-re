import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./ForgottenPasswordSent.gen";

const ForgottenPasswordSent = make;

const meta: Meta<typeof ForgottenPasswordSent> = {
  title: "Pages/Unauthenticated/ForgottenPasswordSent",
  component: ForgottenPasswordSent,
  parameters: {
    layout: "fullscreen",
  },
  args: {
    email: `example@check.beer`,
  },
  argTypes: {
    onGoBack: { action: `onGoBack` },
  },
};

export default meta;

export const Basic: StoryObj<typeof ForgottenPasswordSent> = {};
