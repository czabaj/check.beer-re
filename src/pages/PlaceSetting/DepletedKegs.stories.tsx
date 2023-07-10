import { type Meta, type StoryObj } from "@storybook/react";
import { Timestamp } from "firebase/firestore";

import { make } from "./DepletedKegs.gen";

const meta: Meta<typeof make> = {
  title: "DepletedKegs",
  component: make,
};

export default meta;

const getKegMock = (consumptionLevel: number) => {
  let volume = 30000;
  return {
    beer: "Pilsner Urquell",
    consumptions: Object.fromEntries([
      [
        "1688362302044",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688364131453",
        {
          milliliters: 300,
          person: {},
        },
      ],
      [
        "1688364133571",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688364226633",
        {
          milliliters: 300,
          person: {},
        },
      ],
      [
        "1688405703848",
        {
          person: {},
          milliliters: 500,
        },
      ],
      [
        "1688405705838",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688405707136",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688405708358",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688405714687",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688405716223",
        {
          milliliters: 500,
          person: {},
        },
      ],
      [
        "1688405717366",
        {
          milliliters: 500,
          person: {},
        },
      ],
    ]),
    consumptionsSum: consumptionLevel * volume,
    createdAt: Timestamp.fromMillis(1688481980 * 1000),
    depletedAt: Timestamp.now(),
    milliliters: volume,
    price: 120000,
    recentConsumptionAt: null,
    serial: 3,
    serialFormatted: "#003",
    uid: "wL3VORb19wAd3A0kc6sQ",
  };
};

export const Loading: StoryObj = {
  args: {
    maybeFetchMoreDepletedKegs: undefined,
    maybeDepletedKegs: undefined,
  },
};

export const Loaded: StoryObj = {
  args: {
    maybeFetchMoreDepletedKegs: undefined,
    maybeDepletedKegs: [getKegMock(0.9)],
  },
};
