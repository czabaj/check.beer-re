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
  try {navigatorShare(data)->Promise.then(() => Promise.resolve(Share))} catch {
  | Js.Exn.Error(_) =>
    navigatorWriteToClipboard(data.url)->Promise.then(() => Promise.resolve(Clipboard))
  }
}
