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
  NotificationEvent,
  type FreeTableMessage,
  type FreshKegMessage,
  type UpdateDeviceTokenMessage,
} from "../../src/backend/NotificationEvents";
import { UserRole } from "../../src/backend/UserRoles";
import {
  getNotificationTokensDoc,
  getPersonsIndexDoc,
  getPlacesCollection,
  getPrivateCollection,
} from "./helpers";

const CORS = [`https://check.beer`, /localhost:\d+$/];
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
  { cors: CORS, region: REGION },
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

const getRegistrationTokensFormEvent = async (
  placeDoc: DocumentReference<Place>,
  event: NotificationEvent
): Promise<string[]> => {
  const place = await placeDoc.get();
  if (!place.exists) {
    throw new HttpsError(
      `not-found`,
      `Place "${placeDoc.path}" does not exist.`
    );
  }
  const subscribedAccounts = Object.entries(place.data()!.accounts).filter(
    ([, [, subscribed]]) => subscribed & event
  );
  if (!subscribedAccounts.length) {
    return [];
  }
  const notificationTokensDoc = getNotificationTokensDoc(place.ref.firestore);
  const notificationTokens = (await notificationTokensDoc.get()).data()!.tokens;
  return subscribedAccounts
    .map(([uid]) => notificationTokens[uid])
    .filter(Boolean);
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
export const dispatchNotification = onCall<FreeTableMessage | FreshKegMessage>(
  { cors: CORS, region: REGION },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(`unauthenticated`, `User is not authenticated.`);
    }
    const db = getFirestore();
    const messaging = getMessaging();
    switch (request.data.tag) {
      default:
        throw new HttpsError(
          `invalid-argument`,
          `Unknown value of the notification "tag", received data "${JSON.stringify(
            request.data
          )}".`
        );
      case NotificationEvent.freeTable: {
        const placeDoc = db.doc(request.data.place) as DocumentReference<Place>;
        const subscribedNotificationTokens =
          await getRegistrationTokensFormEvent(
            placeDoc,
            NotificationEvent.freeTable
          );
        if (subscribedNotificationTokens.length === 0) {
          return;
        }
        const currentUserFamiliarName = await getUserFamiliarName(
          placeDoc,
          uid
        );
        return messaging.sendEachForMulticast({
          notification: {
            title: `Ke stolům!`,
            body: `${currentUserFamiliarName} právě zapsal/a první pivo.`,
          },
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
        const subscribedNotificationTokens =
          await getRegistrationTokensFormEvent(
            placeDoc,
            NotificationEvent.freshKeg
          );
        if (subscribedNotificationTokens.length === 0) {
          return;
        }
        const kegData = keg.data()!;
        return messaging.sendEachForMulticast({
          notification: {
            title: `Čerstvé pivo`,
            body: `Právě bylo vytočeno první pivo ze sudu ${kegData.serial}, ${kegData.beer}.`,
          },
          tokens: subscribedNotificationTokens,
        });
      }
    }
  }
);
