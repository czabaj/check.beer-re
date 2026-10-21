---
id: evutu7
status: open
type: bug
created: 2026-10-21T08:27:24Z
---
# Rxjs bindings: error handler calls complete

In `src/Rxjs.res`: `Subscriber.error` binds to "complete", and the distinctBy observer's error handler calls `subscriber.complete(e)`. Errors are swallowed as completion.