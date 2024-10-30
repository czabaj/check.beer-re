import {
  type CollectionReference,
  type DocumentReference,
} from "firebase-admin/firestore";

import type {
  personsIndex,
  place,
} from "../../src/backend/FirestoreModels.gen";

export type NotificationTokensDocument = {
  // maps user uid to their notification token
  tokens: Record<string, string>;
};

export const getPlacesCollection = (db: FirebaseFirestore.Firestore) =>
  db.collection("places") as CollectionReference<place>;

// Only cloud functions have access to this collection.
export const getPrivateCollection = (db: FirebaseFirestore.Firestore) =>
  db.collection("private");

export const getNotificationTokensDoc = (db: FirebaseFirestore.Firestore) =>
  getPrivateCollection(db).doc(
    `notificationTokens`
  ) as DocumentReference<NotificationTokensDocument>;

export const getPersonsIndexDoc = (placeDoc: DocumentReference<place>) =>
  placeDoc
    .collection(`personsIndex`)
    .doc(`1`) as DocumentReference<personsIndex>;
