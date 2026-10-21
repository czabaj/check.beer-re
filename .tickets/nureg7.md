---
id: nureg7
status: closed
type: chore
created: 2026-10-21T08:27:24Z
---
# Replace Belt in reform/ before ReScript 13

62 Belt calls, mostly `src/reform/ReForm.res` and `ReSchema.res` (Belt.Array, Belt.Option.getWithDefault, Belt.Map.String).
Belt moves to a separate `@rescript/belt` package in v13. Migrate to Stdlib or add the package.

## Note 2026-10-21T09:28:08Z

@rescript/belt exists only as 13.0.0-alpha.6, so migrated Belt -> Stdlib instead (uncommitted, for review).
- Mapping: keep->filter, keepMap->filterMap, keepWithIndex->filterWithIndex, getBy->find, concatMany->flat, getExn(i)->get(i)->Option.getOrThrow, Option.getWithDefault->getOr, mapWithDefault->mapOr; rest same names.
- Gotcha: Belt.Array.mapWithIndex is (i, x), Stdlib is (x, i); fixed in ReForm.res fieldArrayUpdateByIndex.
- Deleted dead src/pages/Place/ActiveCheckbox.res (+ .module.css), the only Belt.Map.String user; nothing rendered it.
- Verified: rescript build, vite build, vitest (same pre-existing failure). Zero Belt refs left in src.