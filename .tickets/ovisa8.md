---
id: ovisa8
status: closed
type: chore
created: 2026-10-21T08:27:24Z
---
# Revive or delete dead ReScript tests in tests/

`tests/*.res` are not in rescript.json sources and rescript-vitest was removed; they never compiled. Either wire them up (rescript-vitest 2.x needs vitest 3) or delete.

## Note 2026-10-22T07:18:29Z

Replaced with plain JS vitest tests against .bs.jsx: src/App.test.jsx (asserts link 'Otevřít', old 'Do aplikace' copy was stale; stubs matchMedia + serviceWorker), src/utils/ObjectUtils.test.js. 2cd866f