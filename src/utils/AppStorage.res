open Dom.Storage2

let keyThrustDevice = "thrustDevice"
let keyWebAuthn = "webAuthn"

let getThrustDevice = () => localStorage->getItem(keyThrustDevice)

let useLocalStorage = key => {
  let (internalValue, setInternalValue) = React.useState(() => localStorage->getItem(key))
  let setValue = (. maybeValue) => {
    setInternalValue(_ => maybeValue)
    switch maybeValue {
    | None => localStorage->removeItem(key)
    | Some(value) => localStorage->setItem(key, value)
    }
  }
  React.useEffect0(() => {
    open Webapi
    let listener = _ => {
      setInternalValue(_ => localStorage->getItem(key))
    }
    Dom.window->Dom.Window.addEventListener("storage", listener)
    Some(() => window->Dom.Window.removeEventListener("storage", listener->TypeUtils.any))
  })
  (internalValue, setValue)
}
