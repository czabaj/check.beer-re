---
id: bidul6
status: open
type: bug
created: 2026-10-21T08:27:24Z
---
# Fix Db.test.ts Timestamp assertion (pre-existing failure)

`src/backend/Db.test.ts` "Keg > should compute keg" fails on main too:
`expect.any(Timestamp)` vs a Timestamp from a different firebase module instance.