---
id: enetu5
status: closed
type: chore
created: 2026-10-21T10:02:29Z
---
# Bump firebase to 13

## Note 2026-10-21T10:04:18Z

Bumped to 13.0.0. Yarn v1 left stale nested node_modules/firebase/node_modules (firestore 4.9.1) -> 'updateEmulatorBanner' missing export; fixed by rm -rf node_modules/firebase && yarn install --check-files. build + vitest OK. Rules tests not run: local firebase-tools (volta) broken, missing templates/hosting/init.js. Manual smoke test pending. Pipelines need Firestore Enterprise edition -> not adopted.