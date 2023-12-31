import { action } from "@storybook/addon-actions";
import { type Meta, type StoryObj } from "@storybook/react";
import React from "react";

import { make as InputDonors } from "./InputDonors.gen";

const meta: Meta<typeof InputDonors> = {
  title: "Components/InputDonors",
  component: InputDonors,
};

export default meta;

const Wrapper = (args: any) => {
  const [value, setValue] = React.useState(args.value);
  return (
    <InputDonors
      {...args}
      onChange={(newValue) => {
        action("onChange")(newValue);
        setValue(newValue);
      }}
      value={value}
    />
  );
};

export const Base: StoryObj = {
  args: {
    legendSlot: "Vkladatelé sudu",
    value: { PetrId: 10000 },
    persons: new Map([
      ["PetrId", "Petr"],
      ["JanaId", "Jana"],
      ["KarelId", "Karel"],
    ]),
  },
  render: Wrapper,
};

export const Error: StoryObj = {
  args: {
    errorMessage: "Error message",
    value: {},
    persons: new Map([
      ["PetrId", "Petr"],
      ["JanaId", "Jana"],
      ["KarelId", "Karel"],
    ]),
  },
  render: Wrapper,
};
