import { Timestamp } from "firebase/firestore";
import { type Meta, type StoryObj } from "@storybook/react";

import type {
  personsAllRecord as Db_personsAllRecord,
  userConsumption as Db_userConsumption,
} from "../../../src/backend/Db.gen";
import { make as BeerList } from "./BeerList.gen";

const getPersonRecord = (
  seed: Partial<Db_personsAllRecord>
): Db_personsAllRecord => ({
  balance: 0,
  name: `Lenny`,
  preferredTap: undefined,
  recentActivityAt: Timestamp.now(),
  userId: `user1`,
  ...seed,
});

let uid = 0;
const getConsumptionRecord = (milliliters = 500): Db_userConsumption => ({
  beer: `beer1`,
  consumptionId: String(uid++),
  createdAt: new Date(),
  kegId: `keg1`,
  milliliters,
});

const meta: Meta<typeof BeerList> = {
  title: "Pages/Place/BeerList",
  component: BeerList,
  args: {
    personEntries: Object.entries({
      lenny: getPersonRecord({ name: `Lenny`, userId: `lenny` }),
      karl: getPersonRecord({ name: `Karl`, userId: `karl` }),
    }),
    currentUserUid: `karl`,
    isUserAuthorized: () => true,
    recentConsumptionsByUser: new Map(
      Object.entries({
        lenny: [500, 300, 500].map(getConsumptionRecord),
        karl: [300].map(getConsumptionRecord),
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
      lenny: getPersonRecord({ name: `Lenny`, userId: `lenny` }),
      karl: getPersonRecord({
        name: `Karl Gustavson The Third From Nordic Island`,
        userId: `karl`,
      }),
    }),
    recentConsumptionsByUser: new Map(
      Object.entries({
        lenny: [
          500, 300, 500, 500, 300, 500, 500, 300, 500, 500, 300, 500, 500, 300,
          500, 500, 300, 500, 500, 300, 500, 500, 300, 500, 500, 300, 500, 500,
          300, 500, 500, 300, 500, 500, 300, 500,
        ].map(getConsumptionRecord),
        karl: [300].map(getConsumptionRecord),
      })
    ),
  },
};
