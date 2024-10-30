let isSubscribedToNotificationsRx = (auth, firestore, placeId) => {
  open Rxjs
  let currentUserRx = Rxfire.user(auth)->op(keepMap(Null.toOption))
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)
  combineLatest2(currentUserRx, placeRx)->op(
    map(((currentUser: Firebase.User.t, place: option<FirestoreModels.place>), _) => {
      switch (currentUser, place) {
      | (user, Some(place)) =>
        place.accounts
        ->Dict.get(user.uid)
        ->Option.map(((_, notificationSetting)) => notificationSetting > 0)
        ->Option.getOr(false)
      | _ => false
      }
    }),
  )
}

@react.component
let make = (~placeId) => {
  let auth = Reactfire.useAuth()
  let firestore = Reactfire.useFirestore()
  let messaging = Reactfire.useMessaging()
  let updateNotificationToken = NotificationEvents.useUpdateNotificationToken()
  let isStandaloneModeStatus = DomUtils.useIsStandaloneMode()
  let isSubscribedToNotifications = Reactfire.useObservable(
    ~observableId="isSubscribedToNotifications",
    ~source=isSubscribedToNotificationsRx(auth, firestore, placeId),
  )
  React.useEffect2(() => {
    switch (isSubscribedToNotifications.data, isStandaloneModeStatus.data) {
    | (Some(true), Some(true)) =>
      messaging
      ->Firebase.Messaging.getToken
      ->Promise.then(updateNotificationToken)
      ->Promise.then(_ => Promise.resolve())
      ->Promise.catch(error => {
        let exn = Js.Exn.asJsExn(error)->Option.getExn
        LogUtils.captureException(exn)
        Promise.resolve()
      })
      ->ignore
    | _ => ()
    }
    None
  }, (isSubscribedToNotifications.data, isStandaloneModeStatus.data))

  React.null
}
