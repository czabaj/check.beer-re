type shareData = {
  text: string,
  title: string,
  url: string,
}

type shareHandler = Clipboard | Share

@val @scope("navigator") external navigatorShare: shareData => promise<unit> = "share"

@val @scope("navigator.clipboard")
external navigatorWriteToClipboard: string => promise<unit> = "writeText"

let share = (data: shareData) => {
  try {
    navigatorShare(data)
    ->Promise.catch(err => {
      switch err {
      | Js.Exn.Error(obj) =>
        switch Exn.name(obj) {
        | Some("AbortError") => Promise.resolve()
        | _ => Promise.reject(err)
        }
      | _ => Promise.reject(err)
      }
    })
    ->Promise.then(() => Promise.resolve(Share))
  } catch {
  | Js.Exn.Error(_) =>
    navigatorWriteToClipboard(data.url)->Promise.then(() => Promise.resolve(Clipboard))
  }
}

@get external matches: Window.mediaQueryList => bool = "matches"

let mediaRx = query => {
  open Rxjs
  open! Webapi.Dom
  let mediaQuery = window->Window.matchMedia(query)
  fromEvent(mediaQuery, "change")->pipe2(startWith(mediaQuery), map((list, _) => list->matches))
}

let standaloneModeRx = mediaRx("(display-mode: standalone)")

let useIsStandaloneMode = () => {
  Reactfire.useObservable(~observableId="isStandaloneMode", ~source=standaloneModeRx)
}

let isOnlineRx = {
  open Rxjs
  open! Webapi.Dom
  merge2(
    fromEvent(window, "online")->pipe(map((_, _) => true)),
    fromEvent(window, "offline")->pipe(map((_, _) => false)),
  )->op(startWith((window->Window.navigator).onLine))
}

let useIsOnline = () => {
  Reactfire.useObservable(~observableId="isOnline", ~source=isOnlineRx)
}

let supportsPlatformWebAuthnCache = ref(None)
let supportsPlatformWebAuthn: promise<bool> = %raw(`!window.PublicKeyCredential
  ? Promise.resolve(false)
  : window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()`)->Promise.then(
  result => {
    supportsPlatformWebAuthnCache := Some(result)
    Promise.resolve(result)
  },
)

let useSuportsPlatformWebauthn = () => {
  switch supportsPlatformWebAuthnCache.contents {
  | Some(result) => result
  | None =>
    // throw promise which triggers a Suspense
    raise(supportsPlatformWebAuthn->TypeUtils.any)
  }
}
