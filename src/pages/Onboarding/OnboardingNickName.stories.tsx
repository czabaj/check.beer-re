import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./OnboardingNickName.gen";

const OnboardingNickName = make;

const meta: Meta<typeof OnboardingNickName> = {
  title: "Pages/Onboarding/NickName",
  component: OnboardingNickName,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    onSubmit: { action: `onSubmit` },
  },
};

export default meta;

export const Basic: StoryObj<typeof OnboardingNickName> = {};
