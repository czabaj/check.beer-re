import { action } from "@storybook/addon-actions";
import { type Meta, type StoryObj } from "@storybook/react";
import { within, userEvent } from "@storybook/testing-library";

//@ts-ignore
import * as Styles from "../../styles/components/Styles.bs";
import { make } from "./ButtonMenu.gen";

const meta: Meta<typeof make> = {
  title: "Components/ButtonMenu",
  component: make,
};

export default meta;

export const Base: StoryObj = {
  args: {
    children: "More",
    className: Styles.button.base,
    menuItems: [
      { label: "One", onClick: action("One") },
      { label: "Two", onClick: action("Two") },
      { label: "Three", onClick: action("Three") },
    ],
  },
};

export const Opened: StoryObj = {
  args: {
    children: "More",
    className: Styles.button.base,
    menuItems: [
      { label: "One", onClick: action("One") },
      { label: "Two", onClick: action("Two") },
      { disabled: true, label: "Three", onClick: action("Three") },
    ],
  },
  play: async ({ canvasElement }) => {
    const anchor = await within(canvasElement).getByRole("button");
    await userEvent.click(anchor);
  },
};
