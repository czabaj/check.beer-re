type notificationEvent =
  | @as(0) Unsubscribed
  | @as(1) FreeTable
  | @as(2) FreshKeg
@module("./NotificationEvents.ts")
external notificationEvent: notificationEvent = "NotificationEvent"

let roleI18n = (notificationEvent: notificationEvent) =>
  switch notificationEvent {
  | Unsubscribed => "Nepřihlášen"
  | FreeTable => "Prázdný stůl"
  | FreshKeg => "Čerstvý sud"
  }

type _updateDeviceTokenMessage = {deviceToken: string}
@module("./NotificationEvents.ts")
external updateDeviceTokenMessage: _updateDeviceTokenMessage = "UpdateDeviceTokenMessage"

type _freeTableMessage = {tag: notificationEvent, place: string}
@module("./NotificationEvents.ts")
external freeTableMessage: _freeTableMessage = "FreeTableMessage"

type _freshKegMessage = {tag: notificationEvent, keg: string}
@module("./NotificationEvents.ts")
external freshKegMessage: _freshKegMessage = "FreshKegMessage"

let useDispatchFreeTableNotification = () => {
  let functions = Reactfire.useFunctions()
  let dispatchNotification = Firebase.Functions.httpsCallable(functions, "dispatchNotification")
  (placeRef: Firebase.documentReference<FirestoreModels.place>) =>
    dispatchNotification({tag: FreeTable, place: placeRef.path})
}

let useDispatchFreshKegNotification = () => {
  let functions = Reactfire.useFunctions()
  let dispatchNotification = Firebase.Functions.httpsCallable(functions, "dispatchNotification")
  (kegRef: Firebase.documentReference<FirestoreModels.keg>) =>
    dispatchNotification({tag: FreshKeg, keg: kegRef.path})
}

let useUpdateNotificationToken = () => {
  let functions = Reactfire.useFunctions()
  let updateDeviceToken = Firebase.Functions.httpsCallable(functions, "updateNotificationToken")
  (deviceToken: string) => updateDeviceToken({deviceToken: deviceToken})
}
