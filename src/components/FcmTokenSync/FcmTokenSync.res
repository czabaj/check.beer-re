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
let make = React.memo((~placeId) => {
  // avoid excessive call of the cloud function in development
  if %raw(`import.meta.env.PROD`) && NotificationHooks.canSubscribe {
    let auth = Reactfire.useAuth()
    let firestore = Reactfire.useFirestore()
    let messaging = Reactfire.useMessaging()
    let updateNotificationToken = NotificationHooks.useUpdateNotificationToken()
    let isSubscribedToNotifications = Reactfire.useObservable(
      ~observableId="isSubscribedToNotifications",
      ~source=isSubscribedToNotificationsRx(auth, firestore, placeId),
    )
    React.useEffect(() => {
      switch isSubscribedToNotifications.data {
      | Some(true) =>
        messaging
        ->Firebase.Messaging.getToken
        ->Promise.then(updateNotificationToken)
        ->Promise.then(_ => Promise.resolve())
        ->Promise.catch(
          error => {
            let exn = Js.Exn.asJsExn(error)->Option.getExn
            // ignore the error if the permission is simply blocked
            if %raw(`exn.code !== "messaging/permission-blocked"`) {
              LogUtils.captureException(exn)
            }
            Promise.resolve()
          },
        )
        ->ignore
      | _ => ()
      }
      None
    }, [isSubscribedToNotifications.data])
  }

  React.null
})
