import type { Meta, StoryObj } from "@storybook/react";
import { userEvent, within } from "@storybook/testing-library";

import { make as DrinkDialog } from "./DrinkDialog.gen";
import { getKegMock, getUserConsumptionMock } from "../../test/mockGenerators";
import { dayInMilliseconds } from "../../utils/DateUtils.gen";
import { getFormatConsumption } from "../../utils/BackendUtils.gen";

const meta: Meta<typeof DrinkDialog> = {
  component: DrinkDialog,
  title: "components/DrinkDialog",
  parameters: {
    layout: `centered`,
  },
  args: {
    formatConsumption: getFormatConsumption(null),
    personName: `Vašík`,
    preferredTap: `Hlavní`,
    tapsWithKegs: {
      Hlavní: getKegMock(),
    },
    unfinishedConsumptions: [
      {
        ...getUserConsumptionMock(),
        createdAt: new Date(Date.now() - 8 * dayInMilliseconds),
      },
      {
        ...getUserConsumptionMock(),
        createdAt: new Date(Date.now() - 4 * dayInMilliseconds),
      },
      {
        ...getUserConsumptionMock(),
        createdAt: new Date(Date.now() - dayInMilliseconds),
      },
      getUserConsumptionMock(),
    ],
  },
  argTypes: {
    onDeleteConsumption: { action: "onDeleteConsumption" },
    onDismiss: { action: "onDismiss" },
    onSubmit: { action: "onSubmit" },
  },
};

export default meta;

type Story = StoryObj<typeof DrinkDialog>;

export const Default: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const unfinishedBeersSumarry = await canvas.findByText(`Nezaúčtovaná piva`);
    await userEvent.click(unfinishedBeersSumarry);
  },
};
