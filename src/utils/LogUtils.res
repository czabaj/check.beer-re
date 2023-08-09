%%raw(`import * as Sentry from "@sentry/react";`)

let initSentry: unit => unit = %raw(`() => {
  if (import.meta.env.PROD && window.location.host === 'check.beer') {
    Sentry.init({
      environment: import.meta.env.MODE,
      dsn: "https://85aeb6b971b04c4cb49af3a52f2ad81e@o4505561027903488.ingest.sentry.io/4505561029607424",
    });
  }
}`)

let captureException: Js.Exn.t => unit = %raw(`import.meta.env.PROD && window.location.host === 'check.beer' ? Sentry.captureException : console.error.bind(console)`)

let captureMessage: string => unit = %raw(`import.meta.env.PROD && window.location.host === 'check.beer' ? Sentry.captureMessage : console.log.bind(console)`)

let logEvent = (analytics, eventName, eventParams) => {
  if %raw(`import.meta.env.PROD && window.location.host === 'check.beer'`) {
    Firebase.Analytics.logEvent(. analytics, eventName, eventParams)
  } else {
    Js.log4("%clogEvent", "color: blue", eventName, eventParams)
  }
}

let lastPageView = ref(None)
let usePageView = screenName => {
  let analytics = Reactfire.useAnalytics()
  if lastPageView.contents === Some(screenName) {
    ()
  } else {
    logEvent(analytics, #page_view, {screen_name: screenName})
    lastPageView := Some(screenName)
  }
}
