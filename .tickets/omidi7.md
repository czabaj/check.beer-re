---
id: omidi7
status: closed
type: chore
created: 2026-10-21T08:27:24Z
---
# Clean small pre-existing ReScript issues

- 4 compiler warnings (22 in FormattedVolume `option<...>=?`, 27 unused vars, 45 shadowed Error).
- Broken gentype import `./JsxEvent.gen` in InputToggle.gen.tsx / MyPlaces.gen.tsx (was `JsxEventU.gen` on v11, also broken).
- `DateUtils.monthInMilliseconds` overflows int32.

## Note 2026-10-22T07:18:13Z

Zero warnings; gentype JsxEvent shim (src/JsxEventShim.shim.ts, only Form_t/Mouse_t - extend if other JsxEvent types get @genType); monthInMilliseconds float. 77abd85