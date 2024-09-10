import type { Meta, StoryObj } from "@storybook/react";

import { make as InputToggle } from "./InputToggle.gen";

const meta: Meta<typeof InputToggle> = {
  component: InputToggle,
  title: "components/InputToggle",
  parameters: {
    layout: `centered`,
  },
  args: {},
  argTypes: {
    onChange: { action: "onChange" },
  },
};

export default meta;

type Story = StoryObj<typeof InputToggle>;

export const Default: Story = {};
