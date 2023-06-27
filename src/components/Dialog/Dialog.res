type classesType = {root: string}

@module("./Dialog.module.css") external classes: classesType = "default"

type dialogPolyfillModule = {registerDialog: (. Dom.element) => unit}
@module("dialog-polyfill")
external dialogPolyfill: dialogPolyfillModule = "default"

@send external close: Dom.htmlDialogElement => unit = "close"
@send external showModal: Dom.htmlDialogElement => unit = "showModal"

external toDialogElement: Dom.element => Dom.htmlDialogElement = "%identity"

@react.component
let make = (~children, ~className=?, ~visible) => {
  let (maybeDialogNode, setDialogNode) = React.useState((): option<Dom.htmlDialogElement> => None)
  React.useEffect2(() => {
    switch maybeDialogNode {
    | None => ()
    | Some(dialog) =>
      switch visible {
      | true => dialog->showModal(_)
      | false => dialog->close(_)
      }
    }
    None
  }, (visible, maybeDialogNode))
  <dialog
    className={`${classes.root} ${Js.Option.getWithDefault("", className)}`}
    ref={ReactDOM.Ref.callbackDomRef(node => {
      switch node->Js.Nullable.toOption {
      | Some(dialogNode) => {
          dialogPolyfill.registerDialog(. dialogNode)
          setDialogNode(_ => Some(toDialogElement(dialogNode)))
        }
      | None => setDialogNode(_ => None)
      }
    })}>
    {children}
  </dialog>
}
