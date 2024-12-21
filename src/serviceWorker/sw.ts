import { getMessaging, onBackgroundMessage } from "firebase/messaging/sw";
import { initializeApp } from "firebase/app";
import { CacheableResponsePlugin } from "workbox-cacheable-response";
import { clientsClaim } from "workbox-core";
import { ExpirationPlugin } from "workbox-expiration";
import {
  cleanupOutdatedCaches,
  createHandlerBoundToURL,
  precacheAndRoute,
} from "workbox-precaching";
import { NavigationRoute, registerRoute } from "workbox-routing";
import { NetworkFirst } from "workbox-strategies";

import { firebaseConfig } from "../backend/firebaseConfig";
import type { NotificationData } from "../backend/NotificationEvents";

declare const self: ServiceWorkerGlobalScope;

// Prepared for prompt to update - but currently not used
self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SKIP_WAITING") self.skipWaiting();
});

// Handles auto-update @see https://vite-pwa-org.netlify.app/guide/inject-manifest#auto-update-behavior
self.skipWaiting();
clientsClaim();

const entries = self.__WB_MANIFEST;
if (import.meta.env.DEV) {
  entries.push({ url: "/", revision: Math.random().toString() });
}
precacheAndRoute(entries);

cleanupOutdatedCaches();

if (import.meta.env.PROD) {
  // include webmanifest cache
  registerRoute(
    ({ request, sameOrigin }) =>
      sameOrigin && request.destination === "manifest",
    new NetworkFirst({
      cacheName: "webmanifest",
      plugins: [
        new CacheableResponsePlugin({ statuses: [200] }),
        // we only need a few entries
        new ExpirationPlugin({ maxEntries: 100 }),
      ],
    })
  );
}

registerRoute(
  new NavigationRoute(createHandlerBoundToURL("index.html"), {
    denylist: [
      /__\/auth\//, // exclude webmanifest: has its own cache
      /^\/manifest-(.*).webmanifest$/,
    ],
  })
);

const firebaseApp = initializeApp(firebaseConfig);
const messaging = getMessaging(firebaseApp);
onBackgroundMessage(messaging, (payload) => {
  const data = payload.data as NotificationData;
  self.registration.showNotification(data.title, {
    body: data.body,
    icon: "/pwa-192.png",
    data: { url: data.url || "/" },
  });
});

function findBestClient(clients: WindowClient[]) {
  const focusedClient = clients.find((client) => client.focused);
  const visibleClient = clients.find(
    (client) => client.visibilityState === "visible"
  );

  return focusedClient || visibleClient || clients[0];
}

async function openUrl(url: string) {
  const clients = await self.clients.matchAll({ type: "window" });
  // Chrome 42-48 does not support navigate
  if (clients.length !== 0 && "navigate" in clients[0]) {
    const client = findBestClient(clients as WindowClient[]);
    await client.navigate(url).then((client) => client?.focus());
  }

  await self.clients.openWindow(url);
}

self.addEventListener("notificationclick", (event) => {
  const reactToNotificationClick = new Promise((resolve) => {
    event.notification.close();
    resolve(openUrl(event.notification.data.url || "/"));
  });

  event.waitUntil(reactToNotificationClick);
});
