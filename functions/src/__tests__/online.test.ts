import * as path from "node:path";

import {
  getFirestore,
  Timestamp,
  CollectionReference,
} from "firebase-admin/firestore";
import functions from "firebase-functions-test";

import * as myFunctions from "../index";
import { UserRole } from "../../../src/backend/UserRoles";
import { place } from "../../../src/backend/FirestoreModels.gen";
import { NotificationEvent } from "../../../src/backend/NotificationEvents";

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

describe(`deletePlaceSubcollection`, () => {
  const addPlace = async (opts: { placeId: string; withKegs: boolean }) => {
    const db = getFirestore();
    const placeCollection = db.collection("places");
    const placeDoc = placeCollection.doc(opts.placeId);
    await placeDoc.set({
      createdAt: Timestamp.now(),
      name: "Test Place",
    });
    const result = {
      kegsCollection: undefined as CollectionReference<any> | undefined,
      personsCollection: placeDoc.collection("persons"),
      personsIndexCollection: placeDoc.collection("personsIndex"),
      placeDoc,
    };
    const promises = [
      result.personsCollection.add({
        createdAt: Timestamp.now(),
      }),
      result.personsIndexCollection
        .doc(`1`)
        .set({ all: { tester: ["Tester"] } }),
    ];
    if (opts.withKegs) {
      result.kegsCollection = placeDoc.collection("kegs");
      promises.push(
        result.kegsCollection.add({
          beer: "Test Beer",
          createdAt: Timestamp.now(),
        })
      );
    }
    await Promise.all(promises);
    return result;
  };

  it(`should delete place sub-collestion on placeDelete, new place withou kegs collection`, async () => {
    const { personsCollection, personsIndexCollection, placeDoc } =
      await addPlace({
        placeId: `test_deleteSubCollection_noKegs`,
        withKegs: false,
      });
    const wrapped = testEnv.wrap(myFunctions.deletePlaceSubcollection);
    await wrapped({ params: { placeId: placeDoc.id } });
    expect((await personsCollection.get()).empty).toBe(true);
    expect((await personsIndexCollection.get()).empty).toBe(true);
  });

  it(`should delete place sub-collestion on placeDelete, including kegs`, async () => {
    const { kegsCollection, placeDoc } = await addPlace({
      placeId: `test_deleteSubCollection_withKegs`,
      withKegs: true,
    });
    const wrapped = testEnv.wrap(myFunctions.deletePlaceSubcollection);
    await wrapped({ params: { placeId: placeDoc.id } });
    expect((await kegsCollection!.get()).empty).toBe(true);
  });
});

describe(`truncateUserInDb`, () => {
  const addUserPlace = async (opts: {
    placeId: string;
    userUid: string;
    userRole: UserRole;
    moreUsers?: Array<{ uid: string; role?: UserRole }>;
  }) => {
    const db = getFirestore();
    const placeCollection = db.collection(
      "places"
    ) as CollectionReference<place>;
    const placeDoc = placeCollection.doc(opts.placeId);
    const docData = {
      accounts: {
        [opts.userUid]: [opts.userRole, NotificationEvent.unsubscribed],
        ...opts.moreUsers?.reduce((acc, u) => {
          if (u.role) {
            acc[u.uid] = [u.role, NotificationEvent.unsubscribed];
          }
          return acc;
        }, {} as Record<string, [UserRole, NotificationEvent]>),
      },
      createdAt: Timestamp.now() as any,
      name: "Test Place",
    } satisfies Partial<place>;
    await placeDoc.set(docData as place);
    const personsIndexCollection = placeDoc.collection("personsIndex");
    const personsIndexDocData = {
      [opts.userUid]: [opts.userUid, Timestamp.now(), 0, opts.userUid],
      ...opts.moreUsers?.reduce((acc, u) => {
        acc[u.uid] = [u.uid, Timestamp.now(), 0, u.uid];
        return acc;
      }, {} as Record<string, [string, Timestamp, number, string]>),
    };
    const personsIndexDoc = personsIndexCollection.doc(`1`);
    await personsIndexDoc.set({
      all: personsIndexDocData,
    });

    return { personsIndexDoc, placeDoc };
  };

  it(`should delete the place when it has only connected user`, async () => {
    const placeId = `test_truncateUserInDb_ownerOnly`;
    const userUid = `owner_only`;
    const { placeDoc } = await addUserPlace({
      placeId,
      userUid,
      userRole: UserRole.owner,
    });
    const wrapped = testEnv.wrap(myFunctions.truncateUserInDb);
    await wrapped({ uid: userUid });
    expect((await placeDoc.get()).exists).toBe(false);
  });

  it(`should transfer the ownerhip to the next highest rank`, async () => {
    const placeId = `test_truncateUserInDb_transferOwnership`;
    const userUid = `owner`;
    const { placeDoc } = await addUserPlace({
      placeId,
      userUid,
      userRole: UserRole.owner,
      moreUsers: [
        { uid: `user_staff`, role: UserRole.staff },
        { uid: `user_no_role` },
        { uid: `user_admin`, role: UserRole.admin },
      ],
    });
    const wrapped = testEnv.wrap(myFunctions.truncateUserInDb);
    await wrapped({ uid: userUid });
    const placeData = (await placeDoc.get()).data() as place;
    expect(placeData!.accounts[`user_admin`]).toEqual([
      UserRole.owner,
      NotificationEvent.unsubscribed,
    ]);
  });

  it(`should delete relationship to the user from the place when non-owner`, async () => {
    const placeId = `test_truncateUserInDb_destroyRelationship`;
    const userUid = `owner`;
    const { personsIndexDoc, placeDoc } = await addUserPlace({
      placeId,
      userUid,
      userRole: UserRole.staff,
      moreUsers: [
        { uid: `user_owner`, role: UserRole.owner },
        { uid: `user_no_role` },
      ],
    });
    const wrapped = testEnv.wrap(myFunctions.truncateUserInDb);
    await wrapped({ uid: userUid });
    const placeData = (await placeDoc.get()).data();
    expect(placeData!.accounts[userUid]).toBeUndefined();
    // the personsIndex should contain the user, but with null at 3th position (userId)
    expect((await personsIndexDoc.get()).data()!.all[userUid][3]).toBe(null);
  });

  it(`should handle all places where user parcitipates`, async () => {
    const userUid = `mixed`;
    const placeOwnerOnly = `test_truncateUserInDb_manyPlacesOwnerOnly`;
    const { placeDoc: placeDocOwnerOnly } = await addUserPlace({
      placeId: placeOwnerOnly,
      userUid,
      userRole: UserRole.owner,
    });
    const placeStaff = `test_truncateUserInDb_manyPlacesStaff`;
    const { placeDoc: placeDocStaff } = await addUserPlace({
      placeId: placeStaff,
      userUid,
      userRole: UserRole.staff,
      moreUsers: [
        { uid: `user_owner`, role: UserRole.owner },
        { uid: `user_no_role` },
      ],
    });
    const placeAdmin = `test_truncateUserInDb_manyPlacesAdmin`;
    const { placeDoc: placeDocAdmin } = await addUserPlace({
      placeId: placeAdmin,
      userUid,
      userRole: UserRole.admin,
      moreUsers: [
        { uid: `user_owner`, role: UserRole.owner },
        { uid: `user_no_role` },
      ],
    });
    const wrapped = testEnv.wrap(myFunctions.truncateUserInDb);
    await wrapped({ uid: userUid });
    expect((await placeDocOwnerOnly.get()).exists).toBe(false);
    expect((await placeDocStaff.get()).exists).toBe(true);
    expect((await placeDocStaff.get()).data()!.accounts[userUid]).toBe(
      undefined
    );
    expect((await placeDocAdmin.get()).exists).toBe(true);
    expect((await placeDocAdmin.get()).data()!.accounts[userUid]).toBe(
      undefined
    );
  });
});
