import { Timestamp, arrayUnion } from "@firebase/firestore";
import { describe, expect, it } from "vitest";

import {
  Keg_finalizeGetUpdateObjects,
  kegConverted,
  personsAllRecordToTuple,
} from "./Db.gen";

describe(`Keg`, () => {
  it(`should compute keg`, () => {
    let now = Timestamp.now();
    let kegId = "testKeg";
    let kegSerial = 1;
    let tapName = "testTap";
    let keg: kegConverted = {
      beer: "testBeer",
      consumptions: {
        1: { milliliters: 500, person: { id: `A` } as any },
        2: { milliliters: 500, person: { id: `A` } as any },
      },
      consumptionsSum: 1000,
      createdAt: now,
      depletedAt: null,
      donors: {
        A: 500,
        B: 500,
      },
      milliliters: 1000,
      price: 1000,
      recentConsumptionAt: null,
      serial: kegSerial,
      serialFormatted: "1",
    };
    (keg as any).uid = kegId;
    let personA = {
      balance: 0,
      name: "person A",
      preferredTap: undefined,
      recentActivityAt: now,
      userId: null,
    };
    let personB = {
      balance: 100,
      name: "person B",
      preferredTap: undefined,
      recentActivityAt: now,
      userId: null,
    };
    let place = {
      createdAt: now,
      currency: "EUR",
      name: "testPlace",
      taps: { [tapName]: { id: kegId } as any },
      users: {},
    };
    let personsIndex = {
      all: {
        A: personA,
        B: personB,
      },
    };
    let [
      actualKegUpdataObject,
      actualPersonsUpdateObjects,
      actualPlaceUpdateObject,
      actualPersonsIndexUpdateObject,
    ] = Keg_finalizeGetUpdateObjects(keg, place, personsIndex);
    expect(actualKegUpdataObject).toEqual({
      depletedAt: expect.any(Timestamp),
    });
    expect(actualPlaceUpdateObject).toEqual({
      [`taps.${tapName}`]: null,
    });
    let actualPersonsUpdateObjectsObject = Object.fromEntries(
      actualPersonsUpdateObjects.entries()
    );
    expect(actualPersonsUpdateObjectsObject).toEqual({
      A: {
        transactions: arrayUnion(
          expect.objectContaining({ amount: -1000, keg: kegSerial }),
          expect.objectContaining({ amount: 500, keg: kegSerial })
        ),
      },
      B: {
        transactions: arrayUnion(expect.objectContaining({ amount: 500 })),
      },
    });
    expect(actualPersonsIndexUpdateObject).toEqual({
      "all.A": personsAllRecordToTuple({ ...personA, balance: -500 }),
      "all.B": personsAllRecordToTuple({ ...personB, balance: 600 }),
    });
  });
});
