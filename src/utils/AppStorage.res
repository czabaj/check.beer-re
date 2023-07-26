open Dom.Storage2

let keyRememeberedEmail = "email"
let keyPendingEmail = "email_pending"
let keyThrustDevice = "thrust_device"

let getPendingEmail = () => localStorage->getItem(keyPendingEmail)
let setPendingEmail = email => localStorage->setItem(keyPendingEmail, email)
let removePendingEmail = () => localStorage->removeItem(keyPendingEmail)

let getRememberEmail = () => localStorage->getItem(keyRememeberedEmail)
let setRememberEmail = email => localStorage->setItem(keyRememeberedEmail, email)

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
