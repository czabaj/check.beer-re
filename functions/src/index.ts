/**
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { initializeApp } from "firebase-admin/app";
import {
  type DocumentSnapshot,
  FieldValue,
  type Query,
  getFirestore,
} from "firebase-admin/firestore";
import { auth } from "firebase-functions/v1";
import { firestore } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";

import type {
  place as Place,
  personsIndex as PersonsIndex,
} from "../../src/backend/FirestoreModels.gen";
import { UserRole } from "../../src/backend/UserRoles";

initializeApp();

async function deleteQueryBatch(
  db: FirebaseFirestore.Firestore,
  query: Query,
  resolve: () => void
) {
  const snapshot = await query.get();

  const batchSize = snapshot.size;
  if (batchSize === 0) {
    // When there are no documents left, we are done
    resolve();
    return;
  }

  // Delete documents in a batch
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();

  // Recurse on the next process tick, to avoid
  // exploding the stack.
  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}

async function deleteCollection(
  db: FirebaseFirestore.Firestore,
  collectionPath: string,
  batchSize = 30
) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy("__name__").limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve as any).catch(reject);
  });
}

export const deletePlaceSubcollection = firestore.onDocumentDeleted(
  "/places/{placeId}",
  async (event) => {
    const placeId = event.params.placeId;
    logger.info(`Delete place id: "${placeId}"`);
    const collections = [`kegs`, `persons`, `personsIndex`].map(
      (collection) => `places/${placeId}/${collection}`
    );
    const db = getFirestore();
    for (const collection of collections) {
      await deleteCollection(db, collection);
    }
  }
);

export const truncateUserInDb = auth.user().onDelete(async (user) => {
  const USER_TAG = `Delete user "${user.uid}"`;
  logger.info(USER_TAG);
  const db = getFirestore();
  const placesQuery = db
    .collection("places")
    .where(`accounts.${user.uid}`, `!=`, null);
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
          const placePersonsIndexRef = db.doc(
            `places/${placeSnapshot.id}/personsIndex/1`
          );
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
  return Promise.all(pendingPromises);
});
