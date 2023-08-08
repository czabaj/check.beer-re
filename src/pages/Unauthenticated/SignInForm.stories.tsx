import { type Meta, type StoryObj } from "@storybook/react";
import { userEvent, within } from "@storybook/testing-library";
import { FirebaseError } from "firebase/app";

import { make } from "./SignInForm.gen";

const SignInForm = make;

const meta: Meta<typeof SignInForm> = {
  title: "Pages/Unauthenticated/SignInForm",
  component: SignInForm,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    isOnline: { control: { type: "boolean" } },
    loadingOverlay: { control: { type: `boolean` } },
    onForgottenPassword: { action: `onForgottenPassword` },
    onSignInWithGoogle: { action: `onSignInWithGoogle` },
    onSignInWithPasskey: { action: `onSignInWithPasskey` },
    onSignInWithPassword: { action: `onSignInWithPassword` },
    onSignUp: { action: `onSignUp` },
  },
};

export default meta;

export const Basic: StoryObj<typeof SignInForm> = {};

export const WithError: StoryObj<typeof SignInForm> = {
  args: {
    onSignInWithPassword: () =>
      Promise.reject(
        new FirebaseError(`auth/wrong-password`, `Invalid password`)
      ),
  },
  play: async ({ canvasElement }) => {
    const eMail = await within(canvasElement).findByLabelText(/E.mail/);
    await userEvent.type(eMail, `example@example.com`);
    const password = await within(canvasElement).findByLabelText(`Heslo`);
    await userEvent.type(password, `123456`);
    const submit = await within(canvasElement).findByText(
      `Přihlásit se heslem`
    );
    await userEvent.click(submit);
  },
};
