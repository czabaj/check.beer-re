import fs from "node:fs";

import * as testing from "@firebase/rules-unit-testing";
import { describe, expect, test } from "vitest";

const testUserId = "KQC3YpthFJfKWOrSZhtz5O3Lm302";

describe("Places", () => {
  const testPlaceId = "place1";
  const testKegId = "keg1";

  let testEnv: testing.RulesTestEnvironment;
  let authenticatedUser: testing.RulesTestContext;
  let unauthenticatedUser: testing.RulesTestContext;

  beforeAll(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
      firestore: {
        rules: fs.readFileSync("firestore.rules", "utf8"),
        host: "127.0.0.1",
        port: 9090,
      },
    });

    authenticatedUser = testEnv.authenticatedContext(testUserId);
    unauthenticatedUser = testEnv.unauthenticatedContext();
  });

  beforeEach(async () => {
    // Setup initial user data
    await testEnv.withSecurityRulesDisabled((context) => {
      const firestoreWithoutRule = context.firestore();
      const placeDoc = firestoreWithoutRule
        .collection("places")
        .doc(testPlaceId)
        .set({
          users: {
            [testUserId]: 100,
          },
        });
      const placeKeg = firestoreWithoutRule
        .collection("places")
        .doc(testPlaceId)
        .collection("kegs")
        .doc(testKegId)
        .set({ beer: `Pilsner Urquell` });
      return Promise.all([placeDoc, placeKeg]).then(() => {});
    });

    // Create authenticated and unauthenticated users for testing
    authenticatedUser = testEnv.authenticatedContext(testUserId);
    unauthenticatedUser = testEnv.unauthenticatedContext();
  });

  it(`should not allow to read for unauthenticated users`, async () => {
    const getDoc = unauthenticatedUser
      .firestore()
      .collection("places")
      .doc("random-id")
      .get();

    await testing.assertFails(getDoc);
  });

  it(`should allow list if user has a reference`, async () => {
    const listDocs = authenticatedUser
      .firestore()
      .collection("places")
      .where(`users.${testUserId}`, `>=`, 0);
    await testing.assertSucceeds(listDocs.get());
  });

  it(`should allow get if user has a reference`, async () => {
    const getDoc = authenticatedUser
      .firestore()
      .collection("places")
      .doc(testPlaceId)
      .get();

    await testing.assertSucceeds(getDoc);
  });

  it(`should allow get place subcollection if user can read place`, async () => {
    const getDoc = authenticatedUser
      .firestore()
      .collection("places")
      .doc(testPlaceId)
      .collection("kegs")
      .where(`beer`, `==`, `Pilsner Urquell`)
      .get();

    await testing.assertSucceeds(getDoc);
  });
});

describe("WebAuthnUsers", () => {
  let testEnv: testing.RulesTestEnvironment;
  let authenticatedUser: testing.RulesTestContext;
  let unauthenticatedUser: testing.RulesTestContext;

  beforeAll(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
      firestore: {
        rules: fs.readFileSync("firestore.rules", "utf8"),
        host: "127.0.0.1",
        port: 9090,
      },
    });

    authenticatedUser = testEnv.authenticatedContext(testUserId);
    unauthenticatedUser = testEnv.unauthenticatedContext();
  });

  beforeEach(async () => {
    // Setup initial user data
    await testEnv.withSecurityRulesDisabled((context) => {
      const firestoreWithoutRule = context.firestore();
      return firestoreWithoutRule
        .collection("webAuthnUsers")
        .doc(testUserId)
        .set({ foo: "bar" });
    });

    // Create authenticated and unauthenticated users for testing
    authenticatedUser = testEnv.authenticatedContext(testUserId);
    unauthenticatedUser = testEnv.unauthenticatedContext();
  });

  it(`should not allow to read for unauthenticated user`, async () => {
    const getDoc = unauthenticatedUser
      .firestore()
      .collection("webAuthnUsers")
      .doc("random-id")
      .get();
    await testing.assertFails(getDoc);
  });

  it(`should not allow to read for a random user document`, async () => {
    const getDoc = authenticatedUser
      .firestore()
      .collection("webAuthnUsers")
      .doc("random-id")
      .get();
    await testing.assertFails(getDoc);
  });

  it(`should allow to read the user own document`, async () => {
    const getDoc = authenticatedUser
      .firestore()
      .collection("webAuthnUsers")
      .doc(testUserId)
      .get();
    await testing.assertSucceeds(getDoc);
  });
});
