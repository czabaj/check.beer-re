let isMobileIOs: bool = %raw(`navigator.userAgent.match(/(iPhone|iPad)/)`)
// on iOS the notifications are only allowed in standalone mode
let canSubscribe = !isMobileIOs || %raw(`window.navigator.standalone === true`)

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
  if canSubscribe {
    let auth = Reactfire.useAuth()
    let firestore = Reactfire.useFirestore()
    let messaging = Reactfire.useMessaging()
    let updateNotificationToken = NotificationHooks.useUpdateNotificationToken()
    let isSubscribedToNotifications = Reactfire.useObservable(
      ~observableId="isSubscribedToNotifications",
      ~source=isSubscribedToNotificationsRx(auth, firestore, placeId),
    )
    let serviceWorkerRegistration = Reactfire.useObservable(
      ~observableId="serviceWorkerRegistration",
      ~source=Rxjs.toObservable(ServiceWorker.serviceWorkerRegistrationSubject),
      ~config={
        idField: #uid,
        suspense: false,
      },
    )
    React.useEffect2(() => {
      switch (isSubscribedToNotifications.data, serviceWorkerRegistration.data) {
      | (Some(true), Some(swRegistration)) =>
        messaging
        ->Firebase.Messaging.getToken(swRegistration)
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
    }, (isSubscribedToNotifications.data, serviceWorkerRegistration.data))
  }

  React.null
}
