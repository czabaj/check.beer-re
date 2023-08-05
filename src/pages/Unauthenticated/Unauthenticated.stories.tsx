import { type Meta, type StoryObj } from "@storybook/react";
import { userEvent, within } from "@storybook/testing-library";

import { Pure } from "./Unauthenticated.gen";

const Unauthenticated = Pure.make;

const meta: Meta<typeof Pure.make> = {
  title: "Pages/Unauthenticated",
  component: Unauthenticated,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    initialEmail: { control: `text` },
    onGoogleAuth: { action: `onGoogleAuth` },
    onPasswordAuth: { action: `onPasswordAuth` },
  },
};

export default meta;

export const Basic: StoryObj<typeof Unauthenticated> = {};

export const WithError: StoryObj<typeof Unauthenticated> = {
  args: {
    onPasswordAuth: () => Promise.reject(new Error(`Invalid password`)),
  },
  play: async ({ canvasElement }) => {
    const eMail = await within(canvasElement).findByLabelText(/E.mail/);
    await userEvent.type(eMail, `example@example.com`);
    const password = await within(canvasElement).findByLabelText(`Heslo`);
    await userEvent.type(password, `123456`);
    const submit = await within(canvasElement).findByText(`Přihlásit se heslem`);
    await userEvent.click(submit);
  },
};
