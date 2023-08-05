@module("@sentry/browser")
external captureException: Exn.t => unit = "captureException"

@module("@sentry/browser")
external captureMessage: string => unit = "captureMessage"