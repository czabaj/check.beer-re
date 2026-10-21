---
id: ezija9
status: closed
type: chore
created: 2026-10-21T08:27:24Z
---
# Bump @rescript/react 0.15 + rescript-react-update 6.1

Kept on @rescript/react 0.14 / rescript-react-update ~6.0.0 during the v12 bump.
0.15 requires React/ReactDOM >=19.2 and peer `@rescript/runtime >=12`.
react-update 6.1 requires @rescript/react ^0.15.

## Note 2026-10-21T09:34:56Z

Uncommitted for review. react/react-dom ^19.2.3 (resolved 19.3.1), @rescript/react ^0.15.0, rescript-react-update ^6.1.0, added @rescript/runtime ^12.3.1 as direct dep (peer of @rescript/react; compiled output imports it). Single runtime copy in lockfile.
No code changes; 0.15 only breaking change = requires ReScript 12. Clean build, no new warnings. Vite build ok, dev server ok, vitest same pre-existing failure.
Bundle 1,563 -> 1,601 kB (gzip 405.7 -> 416.8 kB), from react-dom 19.0 -> 19.3.