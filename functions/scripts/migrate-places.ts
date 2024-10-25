import type { App } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { place } from "../../src/backend/FirestoreModels.gen";
import { NotificationEvent } from "../../src/backend/NotificationEvents";

export async function migratePlaces(app: App) {
  const db = getFirestore(app);
  const places = db.collection("places");
  const placesSnap = await places.get();
  const promises: Promise<any>[] = [];
  placesSnap.docs.forEach((placeDoc) => {
    const placeData = placeDoc.data() as place;
    const accounts = {} as place["accounts"];
    if (placeData.users) {
      for (const [uuid, role] of Object.entries(placeData.users)) {
        accounts[uuid] = [role, NotificationEvent.unsubscribed];
      }
    }
    promises.push(
      placeDoc.ref.update({
        accounts,
      })
    );
  });
  return Promise.allSettled(promises);
}
