import { Timestamp } from "firebase/firestore";

import { make } from "./DepletedKegs.bs.js";

const getKegMock = (consumptionLevel) => {
  let volume = 30000;
  return {
    beer: "Pilsner Urquell",
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
