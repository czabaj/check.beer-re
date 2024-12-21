open Dom.Storage2

let keyThrustDevice = "thrustDevice"
let keyWebAuthn = "webAuthn"
let keySeenOfflineModeReady = "seenOfflineModeReady"

let getThrustDevice = () => localStorage->getItem(keyThrustDevice)

let hasSeenOfflineModeReady = () => localStorage->getItem(keySeenOfflineModeReady) !== None
let markSeenOfflineModeReady = () => {
  localStorage->setItem(keySeenOfflineModeReady, "1")
}

let useLocalStorage = key => {
  let (internalValue, setInternalValue) = React.useState(() => localStorage->getItem(key))
  let setValue = maybeValue => {
    setInternalValue(_ => maybeValue)
    switch maybeValue {
    | None => localStorage->removeItem(key)
    | Some(value) => localStorage->setItem(key, value)
    }
  }
  React.useEffect0(() => {
    let listener = _ => {
      setInternalValue(_ => localStorage->getItem(key))
    }
    window->Window.addEventListener("storage", listener)
    Some(() => window->Window.removeEventListener("storage", listener->TypeUtils.any))
  })
  (internalValue, setValue)
}
