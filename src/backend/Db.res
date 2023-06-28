open FirestoreModels

// Resources

let userAccountsCollection = (firestore): Firebase.collectionReference<userAccount> => {
  Firebase.collection(firestore, ~path="users")
}

let placeDocument = (firestore, placeId): Firebase.documentReference<place> => {
  Firebase.doc(firestore, ~path=`places/${placeId}`)
}

let placePersonsCollection = (firestore, placeId): Firebase.collectionReference<person> => {
  Firebase.collection(firestore, ~path=`places/${placeId}/persons`)
}

let placeKegsCollection = (firestore, placeId): Firebase.collectionReference<keg> => {
  Firebase.collection(firestore, ~path=`places/${placeId}/kegs`)
}

// Converters

type placeConverted = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Belt.Map.String.t<(personName, Firebase.Timestamp.t, option<tapName>)>, // converted to Map.String
  taps: Belt.Map.String.t<Js.nullable<Firebase.documentReference<keg>>>, // converted to Map.String
}

let placeConverter: Firebase.dataConverter<place, placeConverted> = {
  fromFirestore: (. snapshot, options) => {
    let {createdAt, currency, name, personsAll, taps} = snapshot.data(. options)
    let personsAllMap = personsAll->Js.Dict.entries->Belt.Map.String.fromArray
    let tapsMap = taps->Js.Dict.entries->Belt.Map.String.fromArray
    {createdAt, currency, name, personsAll: personsAllMap, taps: tapsMap}
  },
  toFirestore: (. place, _) => {
    let {createdAt, currency, name, personsAll, taps} = place
    let tapsDict = taps->Belt.Map.String.toArray->Js.Dict.fromArray
    let personsAllDict = personsAll->Belt.Map.String.toArray->Js.Dict.fromArray
    {createdAt, currency, name, personsAll: personsAllDict, taps: tapsDict}
  },
}

let placeDocumentConverted = (firestore, placeId) => {
  placeDocument(firestore, placeId)->Firebase.withConterterDoc(placeConverter)
}

type kegConverted = {
  beer: string,
  consumptions: array<consumption>,
  consumptionsSum: int, // added by converter
  createdAt: Firebase.Timestamp.t,
  depletedAt: option<Firebase.Timestamp.t>,
  lastConsumptionAt: option<Firebase.Timestamp.t>,
  milliliters: int,
  priceEnd: option<int>,
  priceNew: int,
  serial: int,
}

let kegConverter: Firebase.dataConverter<keg, kegConverted> = {
  fromFirestore: (. snapshot, options) => {
    let keg = snapshot.data(. options)
    let consumptionsSum =
      keg.consumptions->Belt.Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
    {
      beer: keg.beer,
      consumptions: keg.consumptions,
      consumptionsSum,
      createdAt: keg.createdAt,
      depletedAt: keg.depletedAt,
      lastConsumptionAt: keg.lastConsumptionAt,
      milliliters: keg.milliliters,
      priceEnd: keg.priceEnd,
      priceNew: keg.priceNew,
      serial: keg.serial,
    }
  },
  toFirestore: (. keg, _) => {
    let {
      beer,
      consumptions,
      createdAt,
      depletedAt,
      lastConsumptionAt,
      milliliters,
      priceEnd,
      priceNew,
      serial,
    } = keg
    {
      beer,
      consumptions,
      createdAt,
      depletedAt,
      lastConsumptionAt,
      milliliters,
      priceEnd,
      priceNew,
      serial,
    }
  },
}

let placeKegsCollectionConverted = (firestore, placeId) => {
  placeKegsCollection(firestore, placeId)->Firebase.withConterterCollection(kegConverter)
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
        placeKegsCollection(firestore, placeId),
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
  let placeRef = placeDocumentConverted(firestore, placeId)
  Firebase.useFirestoreDocData(placeRef)
}

let useKegsWithRecentConsumptionCollection = placeId => {
  Firebase.useObservable(
    ~observableId="kegsWithRecentConsumption",
    ~source=kegsWithRecentConsumptionRx(placeId, Firebase.useFirestore()),
  )
}

let useKegCollectionStatus = (~limit=20, ~startAfter: option<FirestoreModels.keg>=?, placeId) => {
  let firestore = Firebase.useFirestore()
  let constraints = [Firebase.orderBy("createdAt", ~direction=#desc), Firebase.limit(limit)]
  switch startAfter {
  | None => ()
  | Some(keg) => constraints->Belt.Array.push(Firebase.startAfter(keg))
  }
  let query = Firebase.query(placeKegsCollectionConverted(firestore, placeId), constraints)
  Firebase.useFirestoreCollectionData(query, {})
}

let useMostRecentKegStatus = placeId => {
  let firestore = Firebase.useFirestore()
  let query = Firebase.query(
    placeKegsCollection(firestore, placeId),
    [Firebase.orderBy("serial", ~direction=#desc), Firebase.limit(1)],
  )
  Firebase.useFirestoreCollectionData(query, {})
}
