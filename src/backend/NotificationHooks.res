@genType
type notificationEventMessages =
  | @as(1) /* FreeTable */ FreeTableMessage({place: string, users: array<string>})
  | @as(2) /* FreshKeg */ FreshKegMessage({keg: string, users: array<string>})

@genType
type updateDeviceTokenMessage = {deviceToken: string}

let useGetSubscibedUsers = (
  ~currentUserUid: string,
  ~event: NotificationEvents.notificationEvent,
  ~place: FirestoreModels.place,
) => {
  React.useMemo3(() => {
    place.accounts
    ->Dict.toArray
    ->Array.filterMap(((uid, (_, notificationSubscription))) => {
      if (
        uid === currentUserUid ||
          BitwiseUtils.bitAnd(notificationSubscription, (event :> int)) === 0
      ) {
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
  let subsciredUsers = useGetSubscibedUsers(~currentUserUid, ~event=FreeTable, ~place)
  let freeTableSituation = React.useMemo2(() => {
    subsciredUsers->Array.length > 0 &&
      recentConsumptionsByUser
      ->Map.values
      ->Array.fromIterator
      ->Array.every(consumptions => consumptions->Array.length === 0)
  }, (recentConsumptionsByUser, subsciredUsers))
  () =>
    if freeTableSituation {
      let placeRef = Db.placeDocument(firestore, Db.getUid(place))
      dispatchNotification(FreeTableMessage({place: placeRef.path, users: subsciredUsers}))->ignore
    }
}

let useDispatchFreshKegNotification = (~currentUserUid: string, ~place: FirestoreModels.place) => {
  let firestore = Reactfire.useFirestore()
  let functions = Reactfire.useFunctions()
  let dispatchNotification = Firebase.Functions.httpsCallable(functions, "dispatchNotification")
  let subsciredUsers = useGetSubscibedUsers(~currentUserUid, ~event=FreshKeg, ~place)
  (keg: Db.kegConverted) => {
    let freshKegSituation = subsciredUsers->Array.length > 0 && keg.consumptionsSum === 0
    if freshKegSituation {
      let kegRef = Db.kegDoc(firestore, Db.getUid(place), Db.getUid(keg))
      dispatchNotification(FreshKegMessage({keg: kegRef.path, users: subsciredUsers}))->ignore
    }
  }
}

let useUpdateNotificationToken = () => {
  let functions = Reactfire.useFunctions()
  let updateDeviceToken = Firebase.Functions.httpsCallable(functions, "updateNotificationToken")
  (deviceToken: string) => updateDeviceToken({deviceToken: deviceToken})
}
