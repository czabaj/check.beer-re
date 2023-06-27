open FirestoreModels

// Resources

let kegCollection = (firestore, placeId): Firebase.collectionReference<keg> => {
  Firebase.collection(firestore, ~path=`places/${placeId}/kegs`)
}

let userAccountsCollection = (firestore): Firebase.collectionReference<userAccount> => {
  Firebase.collection(firestore, ~path="users")
}

let placeDocument = (firestore, placeId): Firebase.documentReference<place> => {
  Firebase.doc(firestore, ~path=`places/${placeId}`)
}

// Queries and helpers

let currentUserAccountQuery = (firestore, user: Firebase.User.t) => {
  Firebase.query(userAccountsCollection(firestore), [Firebase.where("email", #"==", user.email)])
}

let currentUserAccountRx = (auth, firestore) => {
  Firebase.userRx(auth)->Rxjs.pipe3(
    Rxjs.switchMap(user => {
      switch Js.Nullable.toOption(user) {
      | None => Rxjs.fromArray([])
      | Some(user) => {
          let query = currentUserAccountQuery(firestore, user)
          Firebase.collectionDataRx(query, {idField: "id"})
        }
      }
    }),
    Rxjs.map(.(currentUsersDocs, _) => Array.at(currentUsersDocs, 0)),
    Rxjs.filter(Option.isSome),
  )
}

let slidingWindowRx = Rxjs.interval(60 * 60 * 1000)->Rxjs.pipe3(
  Rxjs.startWith(0),
  Rxjs.map(.(_, _) => {
    let now = Js.Date.make()
    let monthAgo = Js.Date.setMonth(now, Js.Date.getMonth(now) -. 1.0)
    Firebase.Timestamp.fromMillis(monthAgo)
  }),
  Rxjs.shareReplay(1),
)

let kegsWithRecentConsumptionRx = (placeId, firestore) => {
  slidingWindowRx->Rxjs.pipe(
    Rxjs.switchMap(_slidingWindow => {
      let now = Js.Date.make()
      let monthAgo = Js.Date.setMonth(now, Js.Date.getMonth(now) -. 1.0)
      let firebaseTimestamp = Firebase.Timestamp.fromMillis(monthAgo)
      let query = Firebase.query(
        kegCollection(firestore, placeId),
        [Firebase.where("lastConsumptionAt", #">=", firebaseTimestamp)],
      )
      Firebase.collectionDataRx(query, {})
    }),
  )
}

// Hooks

let useCurrentUserAccountDocData = () => {
  Firebase.useObservable(
    ~observableId="currentUser",
    ~source=currentUserAccountRx(Firebase.useAuth(), Firebase.useFirestore()),
  )
}

let usePlaceDocData = placeId => {
  let firestore = Firebase.useFirestore()
  let placeRef = placeDocument(firestore, placeId)
  Firebase.useFirestoreDocData(placeRef)
}

let useKegsWithRecentConsumptionCollection = placeId => {
  Firebase.useObservable(
    ~observableId="kegsWithRecentConsumption",
    ~source=kegsWithRecentConsumptionRx(placeId, Firebase.useFirestore()),
  )
}
