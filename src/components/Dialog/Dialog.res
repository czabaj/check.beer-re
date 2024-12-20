type classesType = {scrollContent: string, root: string}

@module("./Dialog.module.css") external classes: classesType = "default"

type dialogPolyfillModule = {registerDialog: Dom.element => unit}
@module("dialog-polyfill")
external dialogPolyfill: dialogPolyfillModule = "default"

@send external close: Dom.element => unit = "close"
@send external showModal: Dom.element => unit = "showModal"

@react.component
let make = (~children, ~className=?, ~onClickOutside=?, ~visible) => {
  let (maybeDialogNode, setDialogNode) = React.useState((): option<Dom.element> => None)

  let visibilityDeps = (maybeDialogNode, visible)
  React.useEffect2(() => {
    switch visibilityDeps {
    | (None, _) => ()
    | (Some(dialog), true) => dialog->(showModal(_))
    | (Some(dialog), false) => dialog->(close(_))
    }
    None
  }, visibilityDeps)

  let onClickOutsideRef = React.useRef(onClickOutside)
  onClickOutsideRef.current = onClickOutside
  let lightDismissibleDeps = (maybeDialogNode, onClickOutside !== None)
  React.useEffect2(() => {
    switch lightDismissibleDeps {
    | (Some(dialog), true) => switch dialog->HtmlElement.ofElement {
      | None => None
      | Some(dialogElement) => {
          let handler = event => {
            let targetIsDialog =
              event->MouseEvent.target->EventTarget.unsafeAsElement->Element.nodeName === "DIALOG"
            switch (targetIsDialog, onClickOutsideRef.current) {
            | (true, Some(handleClickOutside)) => handleClickOutside()
            | _ => ()
            }
          }
          dialogElement->HtmlElement.addClickEventListener(handler)
          Some(() => dialogElement->HtmlElement.removeClickEventListener(handler))
        }
      }
    | _ => None
    }
  }, lightDismissibleDeps)

  <dialog
    className={`${classes.root} ${Option.getOr(className, "")}`}
    ref={ReactDOM.Ref.callbackDomRef(node => {
      setDialogNode(_ =>
        switch node->Nullable.toOption {
        | None => None
        | Some(dialogNode) => {
            dialogPolyfill.registerDialog(dialogNode)
            Some(dialogNode)
          }
        }
      )
    })}>
    {children}
  </dialog>
}

module DialogBody = {
  @react.component
  let make = (~children) => {
    <div className={classes.scrollContent}> {children} </div>
  }
}
