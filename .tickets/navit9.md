---
id: navit9
status: closed
type: bug
created: 2026-10-21T09:18:34Z
---
# Storybook build fails: @storybook/testing-library not installed

`npx storybook build` fails: `src/components/ButtonMenu/ButtonMenu.stories.ts` imports `@storybook/testing-library`, which is not a dependency (deprecated; use `@storybook/test`). Independent of the ReScript 12 bump.

## Note 2026-10-22T07:18:13Z

Imports switched to @storybook/test in 3 stories (2ddf0b8). Build failure was a stale local node_modules (storybook 9.1.21 vs lock 8.4.7); yarn install --check-files fixed it, build passes.