open FirestoreModels

// Resources

let kegDoc = (firestore, placeId, kegId): Firebase.documentReference<keg> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/kegs/${kegId}`)
}

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
  taps: Belt.Map.String.t<Js.null<Firebase.documentReference<keg>>>, // converted to Map.String
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
  depletedAt: Null.t<Firebase.Timestamp.t>,
  milliliters: int,
  priceEnd: Null.t<int>,
  priceNew: int,
  recentConsumptionAt: Null.t<Firebase.Timestamp.t>,
  serial: int,
  serialFormatted: string, // added by converter
}

let kegConverter: Firebase.dataConverter<keg, kegConverted> = {
  fromFirestore: (. snapshot, options) => {
    let keg = snapshot.data(. options)
    let consumptionsSum =
      keg.consumptions->Belt.Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
    let serialFormatted = "#" ++ keg.serial->Int.toString->String.padStart(3, "0")
    {
      beer: keg.beer,
      consumptions: keg.consumptions,
      consumptionsSum,
      createdAt: keg.createdAt,
      depletedAt: keg.depletedAt,
      recentConsumptionAt: keg.recentConsumptionAt,
      milliliters: keg.milliliters,
      priceEnd: keg.priceEnd,
      priceNew: keg.priceNew,
      serial: keg.serial,
      serialFormatted,
    }
  },
  toFirestore: (. keg, _) => {
    let {
      beer,
      consumptions,
      createdAt,
      depletedAt,
      recentConsumptionAt,
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
      milliliters,
      priceEnd,
      priceNew,
      recentConsumptionAt,
      serial,
    }
  },
}

let placeKegsCollectionConverted = (firestore, placeId) => {
  placeKegsCollection(firestore, placeId)->Firebase.withConterterCollection(kegConverter)
}

// Queries and helpers

let reactFireOptions: Firebase.reactFireOptions<'a> = {idField: "uid"}

let getUid: 'a => option<string> = %raw("data => data?.uid")

let currentUserAccountQuery = (firestore, user: Firebase.User.t) => {
  Firebase.query(
    userAccountsCollection(firestore),
    [Firebase.where("email", #"==", user.email), Firebase.limit(1)],
  )
}

let currentUserAccountRx = (auth, firestore) => {
  Firebase.userRx(auth)->Rxjs.pipe4(
    Rxjs.switchMap(user => {
      switch Js.Nullable.toOption(user) {
      | None => Rxjs.fromArray([])
      | Some(user) => {
          let query = currentUserAccountQuery(firestore, user)
          Firebase.collectionDataRx(query, reactFireOptions)
        }
      }
    }),
    Rxjs.map(.(currentUsersDocs, _) => Array.at(currentUsersDocs, 0)),
    Rxjs.filter(Option.isSome),
    Rxjs.map(.(surelyCurrentUserData, _) => surelyCurrentUserData->Option.getUnsafe),
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

let kegsWithRecentConsumptionRx = (firestore, placeId) => {
  slidingWindowRx->Rxjs.pipe(
    Rxjs.switchMap(_slidingWindow => {
      let now = Js.Date.make()
      let monthAgo = Js.Date.setMonth(now, Js.Date.getMonth(now) -. 1.0)
      let firebaseTimestamp = Firebase.Timestamp.fromMillis(monthAgo)
      let query = Firebase.query(
        placeKegsCollection(firestore, placeId),
        [Firebase.where("lastConsumptionAt", #">=", firebaseTimestamp)],
      )
      Firebase.collectionDataRx(query, reactFireOptions)
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
    ~source=kegsWithRecentConsumptionRx(Firebase.useFirestore(), placeId),
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
  Firebase.useFirestoreCollectionData(. query, reactFireOptions)
}

let useMostRecentKegStatus = placeId => {
  let firestore = Firebase.useFirestore()
  let query = Firebase.query(
    placeKegsCollection(firestore, placeId),
    [Firebase.orderBy("serial", ~direction=#desc), Firebase.limit(1)],
  )
  Firebase.useFirestoreCollectionData(. query, reactFireOptions)
}

let useChargedKegsStatus = placeId => {
  let firestore = Firebase.useFirestore()
  let query = Firebase.query(
    placeKegsCollectionConverted(firestore, placeId),
    [
      Firebase.orderBy("serial", ~direction=#desc),
      Firebase.where("depletedAt", #"==", null),
      // limit to 50 to avoid expensive calls, but 50 kegs on stock is a lot
      Firebase.limit(50),
    ],
  )
  Firebase.useFirestoreCollectionData(. query, reactFireOptions)
}

// Mutations

let omitUndefined: {..} => {..} = %raw("data => {
  const result = {}
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined) {
      result[key] = value
    }
  }
  return result
}")

type placeUpdate = {
  personsAll?: Belt.Map.String.t<(personName, Firebase.Timestamp.t, option<tapName>)>,
  taps?: Belt.Map.String.t<Js.null<Firebase.documentReference<keg>>>,
}

let updatePlace = (firestore, placeId, data) => {
  let maybePersonsDict =
    data.personsAll->Option.map(personsAll =>
      personsAll->Belt.Map.String.toArray->Js.Dict.fromArray
    )
  let maybeTapsDict = data.taps->Option.map(taps => {
    taps->Belt.Map.String.toArray->Js.Dict.fromArray
  })
  Firebase.updateDoc(
    placeDocument(firestore, placeId),
    omitUndefined({"taps": maybeTapsDict, "personsAll": maybePersonsDict}),
  )
}
