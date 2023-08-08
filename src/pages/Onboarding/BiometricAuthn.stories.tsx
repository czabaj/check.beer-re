import { type Meta, type StoryObj } from "@storybook/react";

import { make } from "./BiometricAuthn.gen";

const BiometricAuthn = make;

const meta: Meta<typeof BiometricAuthn> = {
  title: "Pages/Onboarding/BiometricAuthn",
  component: BiometricAuthn,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    loadingOverlay: { control: { type: `boolean` } },
    onSetupAuthn: { action: `onSetupAuthn` },
    onSkip: { action: `onSkip` },
  },
};

export default meta;

export const Basic: StoryObj<typeof BiometricAuthn> = {};

export const WithError: StoryObj<typeof BiometricAuthn> = {
  args: {
    setupError: ``,
  },
};
