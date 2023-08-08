import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./OnboardingThrustDevice.gen";

const OnboardingThrustDevice = make;

const meta: Meta<typeof OnboardingThrustDevice> = {
  title: "Pages/Onboarding/ThrustDevice",
  component: OnboardingThrustDevice,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    mentionWebAuthn: { type: `boolean` },
    onSkip: { action: `onSkip` },
    onThrust: { action: `onThrust` },
  },
};

export default meta;

export const Basic: StoryObj<typeof OnboardingThrustDevice> = {};
