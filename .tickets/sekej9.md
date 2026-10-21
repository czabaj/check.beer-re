---
id: sekej9
status: open
type: chore
created: 2026-10-21T08:27:24Z
---
# Replace rescript-webapi / rescript-react-intl before ReScript 13

Both compile on v12 only via deprecated `Js.*` / `@uncurry` / `(.` that v13 removes. Unmaintained.
Options: @rescript/webapi (alpha), patch-package, or vendor (`ReactIntl.res` is a single file). Note `-open Webapi.Dom` is global.