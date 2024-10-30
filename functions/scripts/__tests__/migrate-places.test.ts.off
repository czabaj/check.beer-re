import * as path from "node:path";

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { https } from "firebase-functions";
import functions from "firebase-functions-test";

import { place } from "../../../src/backend/FirestoreModels.gen";
import { NotificationEvent } from "../../../src/backend/NotificationEvents";
import { UserRole } from "../../../src/backend/UserRoles";
import { migratePlaces } from "../migrate-places";

const app = initializeApp();

const testEnv = functions(
  {
    projectId: process.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET,
  },
  path.join(__dirname, "../../../certs/beerbook2-da255-1c582faf4499.json")
);

afterAll(() => {
  testEnv.cleanup();
});

const addPlace = async (opts: { placeId: string; users: place["users"] }) => {
  const db = getFirestore();
  const placeCollection = db.collection("places");
  const placeDoc = placeCollection.doc(opts.placeId);
  await placeDoc.set({
    users: opts.users,
  });
  return placeDoc;
};

const migratePlaceFn = https.onCall(async () => {
  await migratePlaces(app);
});

test(`migratePlaces`, async () => {
  const users = {
    owner: UserRole.owner,
    admin: UserRole.admin,
  };
  const placeSeed = {
    placeId: "test-place",
    users,
  };
  const placeDoc = await addPlace(placeSeed);
  const wrapped = testEnv.wrap(migratePlaceFn);
  await wrapped({});
  const actualDocSnap = await placeDoc.get();
  expect(actualDocSnap.data()).toEqual({
    accounts: {
      owner: [UserRole.owner, NotificationEvent.unsubscribed],
      admin: [UserRole.admin, NotificationEvent.unsubscribed],
    },
    users,
  });
});
