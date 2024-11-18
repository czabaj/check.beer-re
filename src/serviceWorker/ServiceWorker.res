// only partially defined, see https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration
type serviceWorkerRegistration = {active: bool}

type registerSWOptions = {
  immediate?: bool,
  onNeedRefresh?: unit => unit,
  onOfflineReady?: unit => unit,
  /**
   * Called once the service worker is registered (requires version `0.12.8+`).
   *
   * @param swScriptUrl The service worker script url.
   * @param registration The service worker registration if available.
   */
  onRegisteredSW?: (string, option<serviceWorkerRegistration>) => unit,
  onRegisterError?: Exn.t => unit,
}

@module("virtual:pwa-register")
external _registerSW: registerSWOptions => unit = "registerSW"

let serviceWorkerRegistrationSubject: Rxjs.ReplaySubject.t<
  serviceWorkerRegistration,
> = Rxjs.ReplaySubject.make(~bufferSize=1)

let registerSW = (options: registerSWOptions) => {
  _registerSW({
    ...options,
    onRegisteredSW: (swUrl, maybeServiceWorkerRegistration) => {
      switch maybeServiceWorkerRegistration {
      | Some(registration) =>
        serviceWorkerRegistrationSubject->Rxjs.ReplaySubject.next(registration)
      | None => ()
      }
      switch options.onRegisteredSW {
      | Some(fn) => fn(swUrl, maybeServiceWorkerRegistration)
      | _ => ()
      }
    },
  })
}
