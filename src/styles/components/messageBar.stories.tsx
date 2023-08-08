import { type Meta, type StoryObj } from "@storybook/react";

import classes from "./messageBar.module.css";

const MessageBar = (props: { variant?: "danger" }) => {
  return (
    <div
      className={`${classes.base} ${
        props.variant === `danger` && classes.variantDanger
      }`}
    >
      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
      veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
      commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
      velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
      cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id
      est laborum.
    </div>
  );
};

const meta: Meta<typeof MessageBar> = {
  title: "Css/MessageBar",
  component: MessageBar,
};

export default meta;

export const Basic: StoryObj<typeof MessageBar> = {};

export const Danger: StoryObj<typeof MessageBar> = {
  args: {
    variant: "danger",
  },
};
