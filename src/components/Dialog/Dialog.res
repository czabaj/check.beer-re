type classesType = {root: string}

@module("./Dialog.module.css") external classes: classesType = "default"

type dialogPolyfillModule = {registerDialog: (. Dom.element) => unit}
@module("dialog-polyfill")
external dialogPolyfill: dialogPolyfillModule = "default"

@send external close: Dom.htmlDialogElement => unit = "close"
@send external showModal: Dom.htmlDialogElement => unit = "showModal"

external toDialogElement: Dom.element => Dom.htmlDialogElement = "%identity"

@react.component
let make = (~children, ~className=?, ~onClickOutside=?, ~visible) => {
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

  let dialogWindowRef = UseHooks.useClickAway(() => {
    switch onClickOutside {
    | None => ()
    | Some(handler) => handler()
    }
  })
  <dialog
    className={`${classes.root} ${Js.Option.getWithDefault("", className)}`}
    ref={ReactDOM.Ref.callbackDomRef(node => {
      setDialogNode(_ =>
        switch node->Js.Nullable.toOption {
        | None => None
        | Some(dialogNode) => {
            dialogPolyfill.registerDialog(. dialogNode)
            Some(toDialogElement(dialogNode))
          }
        }
      )
    })}>
    // The children must be wrapped in extra div for click-outside to work, the dialog element spans the whole screen
    // so I must have a container for just the content of the window
    <div className={`dialogWindow`} ref={dialogWindowRef}> {children} </div>
  </dialog>
}
