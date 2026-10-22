---
id: iyaku8
status: open
type: chore
created: 2026-10-21T08:27:24Z
---
# Move vite-plugin-rescript from 8.0.0-beta.2 to stable

Pinned `@jihchi/vite-plugin-rescript@8.0.0-beta.2` (first version that runs `rescript watch`). Watch upstream issue #242.
Fallback if it breaks: `concurrently "rescript watch" "vite"` + `rescript && vite build`.

## Note 2026-10-22T06:27:42Z

2026-10-22: npm still only 8.0.0-beta.2 (no stable 8.x). Keep pinned, recheck later.

## Note 2026-10-22T07:30:44Z

Workaround createReScriptPluginOnce in vite.config.mts: Storybook builder-vite resolves the config twice (getOptimizeDeps + createServer) with same plugin instance -> 2x rescript watch -> lock error. Plugin only checks old .bsb.lock, not v12 lib/rescript.lock. Drop the wrapper if a stable plugin handles it.