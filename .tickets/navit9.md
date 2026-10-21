---
id: navit9
status: open
type: bug
created: 2026-10-21T09:18:34Z
---
# Storybook build fails: @storybook/testing-library not installed

`npx storybook build` fails: `src/components/ButtonMenu/ButtonMenu.stories.ts` imports `@storybook/testing-library`, which is not a dependency (deprecated; use `@storybook/test`). Independent of the ReScript 12 bump.