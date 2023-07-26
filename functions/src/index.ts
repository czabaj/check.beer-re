/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { initializeApp } from "firebase-admin/app";
// import { Query, getFirestore } from "firebase-admin/firestore";
import { firestore } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";

initializeApp();
// const db = getFirestore();

// async function deleteQueryBatch(query: Query, resolve: () => void) {
//   const snapshot = await query.get();

//   const batchSize = snapshot.size;
//   if (batchSize === 0) {
//     // When there are no documents left, we are done
//     resolve();
//     return;
//   }

//   // Delete documents in a batch
//   const batch = db.batch();
//   snapshot.docs.forEach((doc) => {
//     batch.delete(doc.ref);
//   });
//   await batch.commit();

//   // Recurse on the next process tick, to avoid
//   // exploding the stack.
//   process.nextTick(() => {
//     deleteQueryBatch(query, resolve);
//   });
// }

// // @ts-ignore
// async function deleteCollection(collectionPath: string, batchSize = 100) {
//   const collectionRef = db.collection(collectionPath);
//   const query = collectionRef.orderBy("__name__").limit(batchSize);

//   return new Promise((resolve, reject) => {
//     deleteQueryBatch(query, resolve as any).catch(reject);
//   });
// }

export const deletePlaceSubcollection = firestore.onDocumentDeleted(
  "places/{placeId}",
  async (event) => {
    const placeId = event.params.placeId;
    logger.info(`Delete place id: "${placeId}"`);
    // console.log("Deleted placeId --->>> " + placeId);
    // const collections = [`kegs`, `persons`, `personsIndex`].map(
    //   (collection) => `places/${placeId}/${collection}`
    // );
    // for (const collection of collections) {
    //   await deleteCollection(collection);
    // }
  }
);
