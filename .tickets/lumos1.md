---
id: lumos1
status: open
type: chore
created: 2026-10-26T12:32:41Z
---
# Replace reactfire with own thin module (bundle -150 kB)

Low priority idea, NOT planned. Notes from 2026-10-26 analysis; **re-check every fact below before implementing** (versions, sizes and usage will have drifted).

## Why
- reactfire 4 is effectively unmaintained (peer `firebase@^9`, we are on 13; yarn warns).
- Its ESM build imports `firebase/database`, `firebase/remote-config`, `firebase/storage` at top level and has no `sideEffects: false`, so Rollup keeps them: ~150 kB minified (database ~120, remote-config ~23, storage ~10) that the app never uses. Also duplicate nested versions under `firebase/node_modules/@firebase/*`.
- Measure: `yarn build` then `npx source-map-explorer dist/assets/index-*.js --json`, group by package. NOTE: `yarn build` uploads source maps to Sentry if `.env.sentry-build-plugin` exists; build in a worktree without it or unset the token.

## Usage at the time (check with `grep -rhoE 'Reactfire\.[A-Za-z_.]+' src --include='*.res' | sort | uniq -c`)
- SDK contexts/providers: useFirestore (14), useAuth (8), useFunctions (4), useFirebaseApp (2), useAnalytics (1) + FirebaseAppProvider/AuthProvider/FirestoreProvider/FunctionsProvider/AnalyticsProvider. Messaging already uses own context in src/backend/Reactfire.res.
- useObservable(~observableId, ~source) (8): Suspense until first value, subscription shared/cached per observableId. Pages Place, PlaceSetting, MyPlaces, PlacePersonsSetting, ShareLinkResolver, FcmTokenSync, DomUtils.
- useSigninCheck (1), useFirestoreDocDataWithOptions (1), useFirestoreCollectionData (1) = useObservable over authState / rxfire docData / collectionData (src/backend/Rxfire.res exists).

## Plan sketch
Keep `src/backend/Reactfire.res` interface, replace internals: React contexts for SDK instances; one `useObservable` on `useSyncExternalStore` with a cache keyed by observableId (latest value, pending promise for Suspense, refcounted subscription + delayed teardown); derived hooks as one-liners. ~100-150 lines. Hard part: match reactfire Suspense/cache/error semantics.

## Cheaper alternative
Without replacing reactfire: `build.rollupOptions.treeshake.moduleSideEffects` false for `@firebase/(database|remote-config|storage)` or alias those entries to empty stubs. Breaks silently if the app ever starts using them.

## Rejected alternatives
react-firebase-hooks (stale since 2022, no Suspense, tuple API), TanStack Query Firebase (fetch-cache model fits realtime/RxJS streams poorly, adds TanStack Query).