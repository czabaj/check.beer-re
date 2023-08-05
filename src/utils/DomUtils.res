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

@get external matches: Webapi.Dom.Window.mediaQueryList => bool = "matches"

let mediaRx = query => {
  open Rxjs
  open! Webapi.Dom
  let mediaQuery = window->Window.matchMedia(query)
  fromEvent(. mediaQuery, "change")->pipe2(startWith(mediaQuery), map((list, _) => list->matches))
}

let standaloneModeRx = mediaRx("(display-mode: standalone)")

let useIsStandaloneMode = () => {
  Reactfire.useObservable(~observableId="isStandaloneMode", ~source=standaloneModeRx)
}
