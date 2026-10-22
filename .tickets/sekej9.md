---
id: sekej9
status: open
type: chore
created: 2026-10-21T08:27:24Z
---
# Replace rescript-webapi / rescript-react-intl before ReScript 13

Both compile on v12 only via deprecated `Js.*` / `@uncurry` / `(.` that v13 removes. Unmaintained.
Options: @rescript/webapi (alpha), patch-package, or vendor (`ReactIntl.res` is a single file). Note `-open Webapi.Dom` is global.

## Note 2026-10-22T07:16:19Z

2026-10-22 postponed by user until ReScript 13 is near (not even alpha yet).
- Webapi: successor is https://github.com/rescript-lang/experimental-rescript-webapi (npm @rescript/webapi). Migrate then.
- react-intl: main use is likely relative time (FormattedRelativeTime schedules re-render at next meaningful tick). The JS lib keeps working; only the rescript-react-intl bindings are deprecated. Verify at v13 bump; vendoring ReactIntl.res (407 lines) trimmed to used APIs is the fallback.