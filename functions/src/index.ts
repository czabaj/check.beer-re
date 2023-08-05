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
const db = getFirestore();

async function deleteQueryBatch(query: Query, resolve: () => void) {
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
    deleteQueryBatch(query, resolve);
  });
}

async function deleteCollection(collectionPath: string, batchSize = 30) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy("__name__").limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve as any).catch(reject);
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
    for (const collection of collections) {
      await deleteCollection(collection);
    }
  }
);

export const truncateUserInDb = auth.user().onDelete(async (user) => {
  logger.info(`Delete user`, user);
  const placesQuery = db
    .collection("places")
    .where(`users.${user.uid}`, `>=`, 0);
  const placesToRole: Array<[string, number]> = [];
  placesQuery
    .stream()
    .on(`data`, async (placeSnapshot: DocumentSnapshot<Place>) => {
      const placeData = placeSnapshot.data() as Place;
      const userRole = placeData.users[user.uid];
      placesToRole.push([placeSnapshot.ref.id, userRole]);
      if (userRole === UserRole.owner) {
        placeSnapshot.ref.delete();
      } else {
        const placePersonsIndexRef = db.doc(
          `places/${placeSnapshot.id}/personsIndex/1`
        );
        const placePersonsIndexSnapshot = await placePersonsIndexRef.get();
        const placePersonsIndex =
          placePersonsIndexSnapshot.data() as PersonsIndex;
        const personEntry = Object.entries(placePersonsIndex.all).find(
          ([, personTuple]) => {
            personTuple[3] === user.uid;
          }
        );
        if (personEntry) {
          const [personId, personTuple] = personEntry;
          personTuple[3] = null;
          placePersonsIndexRef.update({
            [`all.${personId}`]: personTuple,
          });
        }
        placeSnapshot.ref.update({
          [`users.${user.uid}`]: FieldValue.delete(),
        });
      }
    })
    .on(`end`, () => {
      logger.info(
        `Delete user "${user.uid}" affected places:`,
        placesToRole.length === 0
          ? `none deleted`
          : Object.fromEntries(placesToRole)
      );
    });
});
