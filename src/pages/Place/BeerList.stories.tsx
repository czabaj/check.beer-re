import { type Meta, type StoryObj } from "@storybook/react";

import { make as BeerList } from "./BeerList.gen";
import { getFormatConsumption } from "../../utils/BackendUtils.gen";
import {
  getPersonMock,
  getUserConsumptionMock,
} from "../../test/mockGenerators";

const meta: Meta<typeof BeerList> = {
  title: "Pages/Place/BeerList",
  component: BeerList,
  args: {
    personEntries: Object.entries({
      lenny: getPersonMock({
        name: `Lenny`,
        preferredTap: "active",
        userId: `lenny`,
      }),
      karl: getPersonMock({
        name: `Karl`,
        preferredTap: "active",
        userId: `karl`,
      }),
    }),
    currentUserUid: `karl`,
    formatConsumption: getFormatConsumption(null),
    isUserAuthorized: () => true,
    recentConsumptionsByUser: new Map(
      Object.entries({
        lenny: [500, 300, 500].map((milliliters) => ({
          ...getUserConsumptionMock(),
          milliliters,
        })),
        karl: [300].map((milliliters) => ({
          ...getUserConsumptionMock(),
          milliliters,
        })),
      })
    ),
  },
};

export default meta;

export const Basic: StoryObj<typeof BeerList> = {};

export const Empty: StoryObj<typeof BeerList> = {
  args: {
    personEntries: [],
  },
};

export const LongConsumption: StoryObj<typeof BeerList> = {
  args: {
    personEntries: Object.entries({
      lenny: getPersonMock({
        name: `Lenny`,
        preferredTap: "active",
        userId: `lenny`,
      }),
      karl: getPersonMock({
        name: `Karl Gustavson The Third From Nordic Island`,
        preferredTap: "active",
        userId: `karl`,
      }),
    }),
    recentConsumptionsByUser: new Map(
      Object.entries({
        lenny: [
          500, 300, 500, 500, 300, 500, 500, 300, 500, 500, 300, 500, 500, 300,
          500, 500, 300, 500, 500, 300, 500, 500, 300, 500, 500, 300, 500, 500,
          300, 500, 500, 300, 500, 500, 300, 500,
        ].map((milliliters) => ({ ...getUserConsumptionMock(), milliliters })),
        karl: [300].map((milliliters) => ({
          ...getUserConsumptionMock(),
          milliliters,
        })),
      })
    ),
  },
};
