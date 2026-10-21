---
id: nureg7
status: open
type: chore
created: 2026-10-21T08:27:24Z
---
# Replace Belt in reform/ before ReScript 13

62 Belt calls, mostly `src/reform/ReForm.res` and `ReSchema.res` (Belt.Array, Belt.Option.getWithDefault, Belt.Map.String).
Belt moves to a separate `@rescript/belt` package in v13. Migrate to Stdlib or add the package.