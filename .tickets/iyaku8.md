---
id: iyaku8
status: open
type: chore
created: 2026-10-21T08:27:24Z
---
# Move vite-plugin-rescript from 8.0.0-beta.2 to stable

Pinned `@jihchi/vite-plugin-rescript@8.0.0-beta.2` (first version that runs `rescript watch`). Watch upstream issue #242.
Fallback if it breaks: `concurrently "rescript watch" "vite"` + `rescript && vite build`.