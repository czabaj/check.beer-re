import { type Meta, type StoryObj } from "@storybook/react";

import { Pure } from "./MyPlaces.gen";

const MyPlaces = Pure.make;

const meta: Meta<typeof MyPlaces> = {
  title: "Pages/MyPlaces",
  component: MyPlaces,
  parameters: {
    layout: "fullscreen",
  },
  argTypes: {
    onPlaceAdd: { action: "onPlaceAdd" },
    onSettingsClick: { action: "onSettingsClick" },
    onSignOut: { action: "onSignOut" },
  },
  args: {
    currentUser: {
      uid: "123",
      displayName: "John Doe",
      metadata: { creationTime: "2021-01-01T00:00:00.000Z" },
    },
    usersPlaces: [],
  },
};

export default meta;

export const Basic: StoryObj<typeof MyPlaces> = {};
