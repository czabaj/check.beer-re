%%raw(`import * as Sentry from "@sentry/react";`)

let initSentry: unit => unit = %raw(`() => {
  if (import.meta.env.PROD) {
    Sentry.init({
      environment: import.meta.env.MODE,
      dsn: "https://85aeb6b971b04c4cb49af3a52f2ad81e@o4505561027903488.ingest.sentry.io/4505561029607424",
    });
  }
}`)

let captureException: Exn.t => unit = %raw(`import.meta.env.PROD ? Sentry.captureException : console.error.bind(console)`)

let captureMessage: string => unit = %raw(`import.meta.env.PROD ? Sentry.captureMessage : console.log.bind(console)`)
