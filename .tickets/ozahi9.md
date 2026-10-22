---
id: ozahi9
status: open
type: bug
created: 2026-10-22T07:18:13Z
---
# Rxjs.res operator externals are curried wrongly

Found in review. In `src/Rxjs.res` (~L143-175) operator externals like `mergeMap: (f, source)`, `concatMap: f => t => t`, `delay`, `distinctUntilChanged`, `distinct`, `buffer` compile to `op(f, source)` — source lands in RxJS's 2nd arg (scheduler/concurrency/keySelector). `delayWhen` typed `unit => t` but RxJS passes `(value, index)`. No callers outside Rxjs.res today, so latent. Fix types to return operator functions, or delete unused bindings.