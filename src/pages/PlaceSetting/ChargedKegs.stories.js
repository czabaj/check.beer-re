import { Timestamp } from "firebase/firestore";

import { make } from "./ChargedKegs.bs.js";

let uid = 0;
const getKegMock = (consumptionLevel) => {
  let volume = 30000;
  let serial = uid++;
  return {
    beer: "Pilsner Urquell",
    consumptionsSum: consumptionLevel * volume,
    createdAt: Timestamp.fromMillis(1688481980 * 1000),
    depletedAt: null,
    milliliters: volume,
    price: 120000,
    recentConsumptionAt: null,
    serial,
    serialFormatted: `#${String(serial).padStart(3, "0")}`,
    uid: String(serial),
  };
};

export default {
  title: "ChargedKegs",
  component: make,
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
  },
};
