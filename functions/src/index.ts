/**
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
import { initializeApp } from "firebase-admin/app";
import {
  type DocumentReference,
  type DocumentSnapshot,
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { auth } from "firebase-functions/v1";
import { firestore } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import type {
  keg as Keg,
  place as Place,
  personsIndex as PersonsIndex,
} from "../../src/backend/FirestoreModels.gen";
import {
  type NotificationData,
  NotificationEvent,
} from "../../src/backend/NotificationEvents";
import type {
  notificationEventMessages as NotificationEventMessages,
  updateDeviceTokenMessage as UpdateDeviceTokenMessage,
} from "../../src/backend/NotificationHooks.gen";
import { UserRole } from "../../src/backend/UserRoles";
import {
  getNotificationTokensDoc,
  getPersonsIndexDoc,
  getPlacesCollection,
  getPrivateCollection,
} from "./helpers";

const CORS = [
  `https://check.beer`,
  /localhost:\d+$/,
  /^https:\/\/beerbook2-da255--pr[\w-]+\.web\.app$/,
];
const REGION = `europe-west3`;

initializeApp();

/**
 * Firestore by default does not support deleting of sub-collections, which might lead to orphaned data. This function
 * listens to a place deletion and deletes all sub-collections of the place.
 */
export const deletePlaceSubcollection = firestore.onDocumentDeleted(
  { document: "/places/{placeId}", region: REGION },
  async (event) => {
    const placeId = event.params.placeId;
    logger.info(`Delete place id: "${placeId}"`);
    const db = getFirestore();
    return db.recursiveDelete(getPlacesCollection(db).doc(placeId));
  }
);

/**
 * When a user is deleted from the Firebase Auth, this removes all their relations to places. If the user is a sole
 * owner of the place, the place is deleted. If there are other accounts associated, the ownership is transferred to
 * second highest role.
 */
export const truncateUserInDb = auth.user().onDelete(async (user) => {
  const USER_TAG = `Delete user "${user.uid}"`;
  logger.info(USER_TAG);
  const db = getFirestore();
  const placesQuery = getPlacesCollection(db).where(
    `accounts.${user.uid}`,
    `!=`,
    null
  );
  const pendingPromises: Promise<any>[] = [];
  await new Promise((resolve, reject) => {
    placesQuery
      .stream()
      .on(`data`, (placeSnapshot: DocumentSnapshot<Place>) => {
        const placeData = placeSnapshot.data() as Place;
        const PLACE_TAG = `place ${placeSnapshot.ref.id}`;
        const promise = (async () => {
          const userRole = placeData.accounts[user.uid][0] as UserRole;
          let newOwner: [string, [number, number]] | undefined;
          if (userRole === UserRole.owner) {
            const otherPlaceUserEntriesByRoleDesc = Object.entries(
              placeData.accounts
            )
              .filter(([uid]) => uid !== user.uid)
              // roles are ints ordered by priviledge, so we can sort them
              .sort(([, [aRole]], [, [bRole]]) => bRole - aRole);
            const ownerOnly = otherPlaceUserEntriesByRoleDesc.length === 0;
            if (ownerOnly) {
              // if the place has only owner, delete the whole place
              await placeSnapshot.ref.delete();
              logger.info(
                USER_TAG,
                PLACE_TAG,
                `only owner, place deleted`,
                placeData
              );
              return;
            } else {
              const secondHighestRank = otherPlaceUserEntriesByRoleDesc[0];
              newOwner = secondHighestRank;
            }
          }
          const placePersonsIndexRef = getPersonsIndexDoc(placeSnapshot.ref);
          const placePersonsIndexSnapshot = await placePersonsIndexRef.get();
          const placePersonsIndex =
            placePersonsIndexSnapshot.data() as PersonsIndex;
          const personEntry = Object.entries(placePersonsIndex.all).find(
            ([, personTuple]) => personTuple[3] === user.uid
          );
          if (personEntry) {
            const [personId, personTuple] = personEntry;
            // person will remain in the list, but without connected account
            personTuple[3] = null;
            await placePersonsIndexRef.update({
              [`all.${personId}`]: personTuple,
            });
          }
          await placeSnapshot.ref.update({
            [`accounts.${user.uid}`]: FieldValue.delete(),
            ...(newOwner && {
              [`accounts.${newOwner[0]}`]: [
                UserRole.owner,
                ...newOwner[1].slice(1),
              ],
            }),
          });
          logger.info(USER_TAG, PLACE_TAG, `user relation removed`);
          if (newOwner) {
            logger.info(
              USER_TAG,
              PLACE_TAG,
              `ownership transferred to ${newOwner}`
            );
          }
        })();
        pendingPromises.push(
          promise.catch((err) => logger.error(USER_TAG, PLACE_TAG, err))
        );
      })
      .on(`end`, resolve)
      .on(`error`, (err) => {
        logger.error(USER_TAG, err);
        reject(err);
      });
  });
  const notificationTokensQuery = getPrivateCollection(db).where(
    `tokens.${user.uid}`,
    `!=`,
    null
  );
  const notificationTokenQuerySnapshot = await notificationTokensQuery.get();
  if (!notificationTokenQuerySnapshot.empty) {
    logger.info(USER_TAG, `user was subscribed to notifications, removing`);
    notificationTokenQuerySnapshot.docs.forEach((doc) => {
      pendingPromises.push(
        doc.ref.update({ [`tokens.${user.uid}`]: FieldValue.delete() })
      );
    });
  }
  return Promise.all(pendingPromises);
});

/**
 * This function has access to a private collection and stores there the notification registration token of the user.
 */
export const updateNotificationToken = onCall<UpdateDeviceTokenMessage>(
  { cors: CORS, enforceAppCheck: true, region: REGION },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(`unauthenticated`, `User is not authenticated.`);
    }
    const { deviceToken } = request.data;
    if (!deviceToken) {
      throw new HttpsError(
        `invalid-argument`,
        `Missing property "deviceToken".`
      );
    }
    const db = getFirestore();
    const notificationTokensDoc = getNotificationTokensDoc(db);
    await notificationTokensDoc.update({
      [`tokens.${uid}`]: request.data.deviceToken,
    });
    return;
  }
);

const getRegistrationTokens = async (
  firestore: FirebaseFirestore.Firestore,
  subscribedAccounts: string[]
): Promise<string[]> => {
  const notificationTokensDoc = getNotificationTokensDoc(firestore);
  const notificationTokens = (await notificationTokensDoc.get()).data()!.tokens;
  return subscribedAccounts
    .map((uid) => notificationTokens[uid])
    .filter(Boolean);
};

const validateRequest = ({
  currentUserUid,
  place,
  subscribedUsers,
}: {
  currentUserUid: string;
  place: DocumentSnapshot<Place>;
  subscribedUsers: string[];
}) => {
  if (subscribedUsers.length === 0) {
    throw new HttpsError(
      `failed-precondition`,
      `There are no subscribed users for the event.`
    );
  }
  if (!place.exists) {
    throw new HttpsError(
      `not-found`,
      `Place "${place.ref.path}" does not exist.`
    );
  }
  const { accounts } = place.data()!;
  if (!accounts[currentUserUid]) {
    throw new HttpsError(
      `permission-denied`,
      `The current user is not associated with the place "${place.ref.path}".`
    );
  }
  if (subscribedUsers.some((uid) => !accounts[uid])) {
    throw new HttpsError(
      `failed-precondition`,
      `Some of the subscribed users are not associated with the place "${place.ref.path}".`
    );
  }
};

const getUserFamiliarName = async (
  placeDoc: DocumentReference<Place>,
  uid: string
) => {
  const placePersonsIndexDoc = getPersonsIndexDoc(placeDoc);
  const placePersonsIndex = await placePersonsIndexDoc.get();
  const currentUserPersonIndex = Object.values(
    placePersonsIndex.data()!.all
  ).find((personsIndexTuple) => personsIndexTuple[3] === uid);
  return currentUserPersonIndex![0];
};

/**
 *
 */
export const dispatchNotification = onCall<NotificationEventMessages>(
  { cors: CORS, enforceAppCheck: true, region: REGION },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(`unauthenticated`, `User is not authenticated.`);
    }
    const db = getFirestore();
    const messaging = getMessaging();
    switch (request.data.TAG) {
      default:
        throw new HttpsError(
          `invalid-argument`,
          `Unknown value of the notification "tag", received data "${JSON.stringify(
            request.data
          )}".`
        );
      case NotificationEvent.freeTable: {
        const placeDoc = db.doc(request.data.place) as DocumentReference<Place>;
        const subscribedUsers = request.data.users;
        const place = await placeDoc.get();
        validateRequest({
          currentUserUid: uid,
          place,
          subscribedUsers,
        });
        const subscribedNotificationTokens = await getRegistrationTokens(
          db,
          subscribedUsers
        );
        if (subscribedNotificationTokens.length === 0) {
          logger.log(
            `No registration tokens stored for notification event`,
            request.data
          );
          return;
        }
        const currentUserFamiliarName = await getUserFamiliarName(
          placeDoc,
          uid
        );
        const placeData = place.data()!;
        return messaging.sendEachForMulticast({
          data: {
            body: `${currentUserFamiliarName} právě zapsal/a první pivo ${placeData.name}`,
            title: `Ke stolu!`,
            url: `https://check.beer/misto/${placeDoc.id}`,
          } satisfies NotificationData,
          tokens: subscribedNotificationTokens,
        });
      }
      case NotificationEvent.freshKeg: {
        const kegDoc = db.doc(request.data.keg) as DocumentReference<Keg>;
        const keg = await kegDoc.get();
        if (!keg.exists) {
          throw new HttpsError(
            `not-found`,
            `Keg "${request.data.keg}" does not exist.`
          );
        }
        const placeDoc = kegDoc.parent.parent as DocumentReference<Place>;
        const subscribedUsers = request.data.users;
        const place = await placeDoc.get();
        validateRequest({
          currentUserUid: uid,
          place,
          subscribedUsers,
        });
        const subscribedNotificationTokens = await getRegistrationTokens(
          db,
          subscribedUsers
        );
        if (subscribedNotificationTokens.length === 0) {
          logger.log(
            `No registration tokens stored for notification event`,
            request.data
          );
          return;
        }
        const kegData = keg.data()!;
        const placeData = place.data()!;
        return messaging.sendEachForMulticast({
          data: {
            body: `${placeData.name} právě vytočili první pivo ze sudu ${kegData.serial}, ${kegData.beer}.`,
            title: `Čerstvé pivo`,
            url: `https://check.beer/misto/${placeDoc.id}`,
          } satisfies NotificationData,
          tokens: subscribedNotificationTokens,
        });
      }
    }
  }
);
