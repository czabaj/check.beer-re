import * as path from "node:path";

import {
  getFirestore,
  Timestamp,
  CollectionReference,
  DocumentReference,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import functions from "firebase-functions-test";

import * as myFunctions from "../index";
import { UserRole } from "../../../src/backend/UserRoles";
import {
  keg,
  personsIndex,
  place,
} from "../../../src/backend/FirestoreModels.gen";
import { NotificationEvent } from "../../../src/backend/NotificationEvents";
import type {
  notificationEventMessages as NotificationEventMessages,
  updateDeviceTokenMessage as UpdateDeviceTokenMessage,
} from "../../../src/backend/NotificationHooks.gen";
import {
  getNotificationTokensDoc,
  getPersonsIndexDoc,
  getPlacesCollection,
  NotificationTokensDocument,
} from "../helpers";

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
    const placeCollection = getPlacesCollection(db);
    const placeDoc = placeCollection.doc(opts.placeId);
    await placeDoc.set({
      createdAt: Timestamp.now(),
      name: "Test Place",
    } as any);
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

  it(`should also delete the user from the document with notification tokens`, async () => {
    const userUid = `beatle`;
    const db = getFirestore();
    const notificationTokensDoc = getNotificationTokensDoc(db);
    await notificationTokensDoc.set({
      tokens: { [userUid]: `registrationToken` },
    });
    const notificationTokensBefore = (
      await notificationTokensDoc.get()
    ).data()!;
    expect(notificationTokensBefore.tokens[userUid]).toBe(`registrationToken`);
    const wrapped = testEnv.wrap(myFunctions.truncateUserInDb);
    await wrapped({ uid: userUid });
    const notificationTokensAfter = (await notificationTokensDoc.get()).data()!;
    expect(notificationTokensAfter.tokens[userUid]).toBeUndefined();
  });
});

describe(`updateNotificationToken`, () => {
  const db = getFirestore();
  const notificationTokensDoc = getNotificationTokensDoc(db);
  it(`should add a user to notification collection if not there`, async () => {
    const userUid = `eleanor`;
    const deviceToken = `testingDeviceToken`;
    await notificationTokensDoc.set({ tokens: {} });
    const wrapped = testEnv.wrap(myFunctions.updateNotificationToken);
    await wrapped({
      auth: { uid: userUid },
      data: {
        deviceToken,
      } satisfies UpdateDeviceTokenMessage,
    });
    const notificationTokens = (await notificationTokensDoc.get()).data()!;
    expect(notificationTokens.tokens[userUid]).toBe(deviceToken);
  });
  it(`should update the user token if already there`, async () => {
    const uid = `condor`;
    const oldDeviceToken = `oldDeviceToken`;
    const newDeviceToken = `newDeviceToken`;
    await notificationTokensDoc.set({ tokens: { [uid]: oldDeviceToken } });
    const wrapped = testEnv.wrap(myFunctions.updateNotificationToken);
    await wrapped({
      auth: { uid },
      data: { deviceToken: newDeviceToken } satisfies UpdateDeviceTokenMessage,
    });
    const notificationTokens = (await notificationTokensDoc.get()).data()!;
    expect(notificationTokens.tokens[uid]).toBe(newDeviceToken);
  });
});

describe(`dispatchNotification`, () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });
  it(`should use jest automock for messaging`, () => {
    const messaging = getMessaging();
    expect(messaging.sendEachForMulticast).toHaveBeenCalledTimes(0);
  });

  const createPlace = async (opts: {
    placeId: string;
    keg?: {
      beer: string;
      serial: number;
    };
    users: Array<{
      accountTuple: [UserRole, NotificationEvent];
      name: string;
      registrationToken: string;
      uid: string;
    }>;
  }) => {
    const db = getFirestore();
    const placeCollection = getPlacesCollection(db);
    const placeDoc = placeCollection.doc(opts.placeId);
    const accounts: place["accounts"] = opts.users.reduce((acc, u) => {
      acc[u.uid] = u.accountTuple;
      return acc;
    }, {} as place["accounts"]);
    await placeDoc.set({
      accounts: accounts,
      createdAt: Timestamp.now(),
      name: "Test Place",
    } as any);
    const personsIndexDoc = getPersonsIndexDoc(placeDoc);
    const personsIndexAll: personsIndex["all"] = opts.users.reduce((acc, u) => {
      acc[u.uid] = [u.name, Timestamp.now(), 0, u.uid] as any;
      return acc;
    }, {} as personsIndex["all"]);
    await personsIndexDoc.set({
      all: personsIndexAll,
    });
    const notificationTokensDoc = getNotificationTokensDoc(db);
    const tokens: NotificationTokensDocument["tokens"] = opts.users.reduce(
      (acc, u) => {
        acc[u.uid] = u.registrationToken;
        return acc;
      },
      {} as NotificationTokensDocument["tokens"]
    );
    await notificationTokensDoc.set({ tokens });
    let kegDoc: DocumentReference<keg> | undefined;
    if (opts.keg) {
      const kegsCollection = placeDoc.collection(
        "kegs"
      ) as CollectionReference<keg>;
      kegDoc = await kegsCollection.add({
        beer: opts.keg.beer,
        createdAt: Timestamp.now(),
        serial: opts.keg.serial,
      } as any);
    }
    return { kegDoc, placeDoc, personsIndexDoc, notificationTokensDoc };
  };

  it(`should dispatch a notification for freeTable message to subscribed users`, async () => {
    const { placeDoc } = await createPlace({
      placeId: `testDispatchNotification_freeTable`,
      users: [
        {
          accountTuple: [UserRole.owner, NotificationEvent.freeTable],
          name: `Alice`,
          registrationToken: `registrationToken1`,
          uid: `user1`,
        },
        {
          accountTuple: [
            UserRole.staff,
            NotificationEvent.freeTable | NotificationEvent.freshKeg,
          ],
          name: `Bob`,
          registrationToken: `registrationToken2`,
          uid: `user2`,
        },
        {
          accountTuple: [UserRole.admin, NotificationEvent.unsubscribed],
          name: `Dan`,
          registrationToken: `registrationToken3`,
          uid: `user3`,
        },
      ],
    });
    const wrapped = testEnv.wrap(myFunctions.dispatchNotification);
    await wrapped({
      auth: { uid: `user1` },
      data: {
        TAG: NotificationEvent.freeTable,
        place: placeDoc.path,
        users: [`user2`],
      } satisfies NotificationEventMessages,
    });
    const messaging = getMessaging();
    expect(messaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    const callArg = (messaging.sendEachForMulticast as any).mock.calls[0][0];
    expect(callArg.tokens).toEqual([`registrationToken2`]);
    expect(callArg.notification.body.startsWith(`Alice`)).toBe(true);
  });
  it(`should dispatch notification for freshKeg message to subscribed users`, async () => {
    const { kegDoc } = await createPlace({
      keg: {
        beer: `Test Beer`,
        serial: 1,
      },
      placeId: `testDispatchNotification_freshKeg`,
      users: [
        {
          accountTuple: [UserRole.owner, NotificationEvent.freshKeg],
          name: `Alice`,
          registrationToken: `registrationToken1`,
          uid: `user1`,
        },
        {
          accountTuple: [
            UserRole.staff,
            NotificationEvent.freeTable | NotificationEvent.freshKeg,
          ],
          name: `Bob`,
          registrationToken: `registrationToken2`,
          uid: `user2`,
        },
        {
          accountTuple: [UserRole.admin, NotificationEvent.unsubscribed],
          name: `Dan`,
          registrationToken: `registrationToken3`,
          uid: `user3`,
        },
      ],
    });
    const wrapped = testEnv.wrap(myFunctions.dispatchNotification);
    await wrapped({
      auth: { uid: `user1` },
      data: {
        TAG: NotificationEvent.freshKeg,
        keg: kegDoc!.path,
        users: [`user2`],
      } satisfies NotificationEventMessages,
    });
    const messaging = getMessaging();
    expect(messaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    const callArg = (messaging.sendEachForMulticast as any).mock.calls[0][0];
    expect(callArg.tokens).toEqual([`registrationToken2`]);
    expect(callArg.notification.body.includes(`Test Beer`)).toBe(true);
  });
});
