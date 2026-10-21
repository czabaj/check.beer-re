---
id: awubo7
status: closed
type: chore
created: 2026-10-21T11:23:53Z
---
# Bump Vite to 8 (+plugin-react 6, vite-plugin-pwa 2, vitest 5)

## Note 2026-10-21T11:25:17Z

vite 7.1.3->8.3.5 (Rolldown), @vitejs/plugin-react 5->6, vite-plugin-pwa 1->2, vitest 2->5. Config: reference types vitest -> vitest/config. build, vitest, dev server OK. 'inlineDynamicImports deprecated' warning comes from vite-plugin-pwa SW build, not our config. Storybook left on 8 -> okoke1. Rules tests not run (firebase-tools broken locally).