---
id: bidul6
status: closed
type: bug
created: 2026-10-21T08:27:24Z
---
# Fix Db.test.ts Timestamp assertion (pre-existing failure)

`src/backend/Db.test.ts` "Keg > should compute keg" fails on main too:
`expect.any(Timestamp)` vs a Timestamp from a different firebase module instance.

## Note 2026-10-22T07:18:13Z

Could not reproduce on firebase 13 install; hardened test to import Timestamp from firebase/firestore (same entry as Firebase.res). 7ef020a