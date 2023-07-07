import * as Belt_MapString from "rescript/lib/es6/belt_MapString.js";
import { Timestamp } from "firebase/firestore";

import { make } from "./DepletedKegs.bs.js";

const getKegMock = (consumptionLevel) => {
  let volume = 30000;
  return {
    beer: "Pilsner Urquell",
    consumptions: Belt_MapString.fromArray([
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

export default {
  title: "DepletedKegs",
  component: make,
};

export const Loading = {
  args: {
    maybeFetchMoreDepletedKegs: undefined,
    maybeDepletedKegs: undefined,
  },
};

export const Loaded = {
  args: {
    maybeFetchMoreDepletedKegs: undefined,
    maybeDepletedKegs: [getKegMock(0.9)],
  },
};
