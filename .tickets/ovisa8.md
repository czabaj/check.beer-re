---
id: ovisa8
status: open
type: chore
created: 2026-10-21T08:27:24Z
---
# Revive or delete dead ReScript tests in tests/

`tests/*.res` are not in rescript.json sources and rescript-vitest was removed; they never compiled. Either wire them up (rescript-vitest 2.x needs vitest 3) or delete.