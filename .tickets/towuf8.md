---
id: towuf8
status: closed
type: chore
created: 2026-10-21T09:15:10Z
---
# Adopt ReScript 12 syntax: dict/regex literals, JSX preserve

## Note 2026-10-21T09:18:34Z

Uncommitted for user review.
- Regex literals: already done by the v12 formatter in ac5a05b (%re -> /.../). Only remaining RegExp.fromString is dynamic (ReSchema).
- Dict literals: only static keys allowed; all Dict.fromArray/Object.set use computed keys. Converted the 3 Dict.make() -> dict{}.
- JSX preserve: jsx.preserve=true + suffix .bs.jsx (Vite won't parse JSX in .js). Updated .gitignore, index.html, ChargedKegs.stories.js, vite.config comment; gen.tsx imports regenerated. Deps compile with root suffix too.
- Verified: rescript build, vite build (11s warm), dev server serves .bs.jsx, vitest (same pre-existing failure). Output keeps an unused `react/jsx-runtime` import per file (harmless).
- After pulling: run `yarn clean` or delete stale *.bs.js.