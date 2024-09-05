import { Timestamp } from "firebase/firestore";
import { kegConverted, userConsumption } from "../backend/Db.gen";
import {
  hourInMilliseconds,
  monthInMilliseconds,
} from "../utils/DateUtils.gen";

export const getRandomDateInstanceInHistory = (
  lowerBound: Date | number | string = Date.now() - monthInMilliseconds
): Date => {
  const now = new Date();
  const diff = (now as any) - (new Date(lowerBound) as any);
  return new Date(Date.now() - Math.round(Math.random() * diff));
};

export const getRandomDateInHistory = (
  lowerBound: Date | number | string = Date.now() - monthInMilliseconds
): string => {
  return getRandomDateInstanceInHistory(lowerBound).toISOString();
};

export const getKegMock = (): kegConverted => {
  return {
    beer: `Pilsner Urquell`,
    consumptions: {},
    consumptionsSum: 0,
    createdAt: Timestamp.fromDate(getRandomDateInstanceInHistory()),
    donors: {},
    depletedAt: null,
    milliliters: 50000,
    price: 1000,
    recentConsumptionAt: null,
    serial: 1,
    serialFormatted: `1`,
  };
};

export const getUserConsumptionMock = (): userConsumption => {
  return {
    consumptionId: `1`,
    kegId: `1`,
    beer: `Pilsner Urquell`,
    milliliters: 500,
    createdAt: getRandomDateInstanceInHistory(Date.now() - hourInMilliseconds),
  };
};
