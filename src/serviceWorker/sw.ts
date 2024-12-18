import { getMessaging, onBackgroundMessage } from "firebase/messaging/sw";
import { initializeApp } from "firebase/app";
import { clientsClaim } from "workbox-core";
import { cleanupOutdatedCaches, precacheAndRoute } from "workbox-precaching";

import { firebaseConfig } from "../backend/firebaseConfig";

declare const self: ServiceWorkerGlobalScope;

self.skipWaiting();
clientsClaim();

cleanupOutdatedCaches();

precacheAndRoute(self.__WB_MANIFEST);

self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SKIP_WAITING") self.skipWaiting();
});

const firebaseApp = initializeApp(firebaseConfig);
const messaging = getMessaging(firebaseApp);
onBackgroundMessage(messaging, (payload) => {
  const notificationTitle = payload.notification?.title;
  if (!notificationTitle) return;
  self.registration.showNotification(notificationTitle, {
    body: payload.notification!.body,
    icon: "/pwa-192.png",
  });
});
