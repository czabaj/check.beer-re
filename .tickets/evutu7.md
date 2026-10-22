---
id: evutu7
status: closed
type: bug
created: 2026-10-21T08:27:24Z
---
# Rxjs bindings: error handler calls complete

In `src/Rxjs.res`: `Subscriber.error` binds to "complete", and the distinctBy observer's error handler calls `subscriber.complete(e)`. Errors are swallowed as completion.

## Note 2026-10-22T07:18:13Z

Subscriber.error now binds "error" (distinctBy already used Subscriber.error). 22544dd