let isMobileIOs: bool = %raw(`navigator.userAgent.match(/(iPhone|iPad)/)`)
let canSubscribe =
  %raw(`"Notification" in window`) &&
  (// on iOS the notifications are only allowed in standalone mode
  !isMobileIOs || %raw(`window.navigator.standalone === true`))

@genType
type notificationEventMessages =
  | @as(1) /* FreeTable */ FreeTableMessage({place: string, users: array<string>})
  | @as(2) /* FreshKeg */ FreshKegMessage({keg: string, users: array<string>})

@genType
type updateDeviceTokenMessage = {deviceToken: string}

@val @scope(("window", "Notification"))
external notificationPermission: [#default | #denied | #granted] = "permission"

let useGetSubscibedUsers = (
  ~currentUserUid: string,
  ~event: NotificationEvents.notificationEvent,
  ~place: FirestoreModels.place,
) => {
  React.useMemo3(() => {
    place.accounts
    ->Dict.toArray
    ->Array.filterMap(((uid, (_, notificationSubscription))) => {
      if uid === currentUserUid || land(notificationSubscription, (event :> int)) === 0 {
        None
      } else {
        Some(uid)
      }
    })
  }, (currentUserUid, event, place))
}

let useDispatchFreeTableNotification = (
  ~currentUserUid: string,
  ~place: FirestoreModels.place,
  ~recentConsumptionsByUser,
) => {
  let firestore = Reactfire.useFirestore()
  let functions = Reactfire.useFunctions()
  let dispatchNotification = Firebase.Functions.httpsCallable(functions, "dispatchNotification")
  let subscribedUsers = useGetSubscibedUsers(~currentUserUid, ~event=FreeTable, ~place)
  let freeTableSituation = React.useMemo2(() => {
    subscribedUsers->Array.length > 0 &&
      recentConsumptionsByUser
      ->Map.values
      ->Array.fromIterator
      ->Array.every(consumptions => consumptions->Array.length === 0)
  }, (recentConsumptionsByUser, subscribedUsers))
  () =>
    if freeTableSituation {
      let placeRef = Db.placeDocument(firestore, Db.getUid(place))
      dispatchNotification(FreeTableMessage({place: placeRef.path, users: subscribedUsers}))->ignore
    }
}

let useDispatchFreshKegNotification = (~currentUserUid: string, ~place: FirestoreModels.place) => {
  let firestore = Reactfire.useFirestore()
  let functions = Reactfire.useFunctions()
  let dispatchNotification = Firebase.Functions.httpsCallable(functions, "dispatchNotification")
  let subscribedUsers = useGetSubscibedUsers(~currentUserUid, ~event=FreshKeg, ~place)
  (keg: Db.kegConverted) => {
    let freshKegSituation = subscribedUsers->Array.length > 0 && keg.consumptionsSum === 0
    if freshKegSituation {
      let kegRef = Db.kegDoc(firestore, Db.getUid(place), Db.getUid(keg))
      dispatchNotification(FreshKegMessage({keg: kegRef.path, users: subscribedUsers}))->ignore
    }
  }
}

let useDispatchTestNotification = (~currentUserUid: string, ~place: FirestoreModels.place) => {
  let firestore = Reactfire.useFirestore()
  let functions = Reactfire.useFunctions()
  let dispatchNotification = Firebase.Functions.httpsCallable(functions, "dispatchNotification")
  () => {
    let placeRef = Db.placeDocument(firestore, Db.getUid(place))
    dispatchNotification(FreeTableMessage({place: placeRef.path, users: [currentUserUid]}))->ignore
  }
}

let useUpdateNotificationToken = () => {
  let functions = Reactfire.useFunctions()
  let updateDeviceToken = Firebase.Functions.httpsCallable(functions, "updateNotificationToken")
  (deviceToken: string) => updateDeviceToken({deviceToken: deviceToken})
}
