import { Timestamp } from "firebase/firestore";

import { make } from "./ChargedKegsSetting.bs.js";

const getKegMock = (consumptionLevel) => {
  let volume = 30000;
  return {
    beer: "Pilsner Urquell",
    consumptionsSum: consumptionLevel * volume,
    createdAt: Timestamp.fromMillis(1688481980 * 1000),
    depletedAt: null,
    milliliters: volume,
    price: 120000,
    recentConsumptionAt: null,
    serial: 3,
    serialFormatted: "#003",
    uid: "wL3VORb19wAd3A0kc6sQ",
  };
};

export default {
  title: "ChargedKegsSetting",
  component: make,
  tags: ["autodocs"],
};

export const Base = {
  args: {
    chargedKegs: [
      getKegMock(0),
      getKegMock(0.3),
      getKegMock(0.5),
      getKegMock(0.7),
      getKegMock(0.9),
      getKegMock(1),
    ],
    place: {},
    placeId: "1",
  },
};
