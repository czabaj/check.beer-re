import { Timestamp, arrayUnion } from "@firebase/firestore";
import { describe, expect, it } from "vitest";

import {
  Keg_finalizeGetUpdateObjects,
  kegConverted,
  personsAllRecordToTuple,
  placeConverted,
} from "./Db.gen";

describe(`Keg`, () => {
  it(`should compute keg`, () => {
    let now = Timestamp.now();
    let kegId = "testKeg";
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
      serial: 1,
      serialFormatted: "1",
    };
    let personA = {
      balance: 0,
      name: "person A",
      preferredTap: undefined,
      recentActivityAt: now,
    };
    let personB = {
      balance: 100,
      name: "person B",
      preferredTap: undefined,
      recentActivityAt: now,
    };
    let place: placeConverted = {
      createdAt: now,
      currency: "EUR",
      name: "testPlace",
      personsAll: {
        A: personA,
        B: personB,
      },
      taps: { testTap: { id: kegId } as any },
    };
    let [
      actualKegUpdataObject,
      actualPersonsUpdateObjects,
      actualPlaceUpdateObject,
    ] = Keg_finalizeGetUpdateObjects(keg, place);
    expect(actualKegUpdataObject).toEqual({
      depletedAt: expect.any(Timestamp),
    });
    let actualPersonsUpdateObjectsObject = Object.fromEntries(
      actualPersonsUpdateObjects.entries()
    );
    expect(actualPersonsUpdateObjectsObject).toEqual({
      A: {
        transactions: arrayUnion(
          expect.objectContaining({ amount: -1000 }),
          expect.objectContaining({ amount: 500 })
        ),
      },
      B: {
        transactions: arrayUnion(expect.objectContaining({ amount: 500 })),
      },
    });
    expect(actualPlaceUpdateObject).toEqual({
      "personsAll.A": personsAllRecordToTuple({ ...personA, balance: -500 }),
      "personsAll.B": personsAllRecordToTuple({ ...personB, balance: 600 }),
    });
  });
});
