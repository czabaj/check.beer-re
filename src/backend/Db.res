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

let placePersonDocument = (firestore, placeId, personId): Firebase.documentReference<person> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/persons/${personId}`)
}

let placeKegsCollection = (firestore, placeId): Firebase.collectionReference<keg> => {
  Firebase.collection(firestore, ~path=`places/${placeId}/kegs`)
}

let placeKegDocument = (firestore, placeId, kegId): Firebase.documentReference<keg> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/kegs/${kegId}`)
}

// Converters

type personsAllRecord = {
  name: string,
  preferredTap: option<string>,
  recentActivityAt: Firebase.Timestamp.t,
}

let personsAllRecordToTuple = ({
  name,
  preferredTap,
  recentActivityAt,
}): FirestoreModels.personsAllItem => (name, recentActivityAt, preferredTap->Null.fromOption)

type placeConverted = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Belt.Map.String.t<personsAllRecord>, // converted to Map.String
  taps: Belt.Map.String.t<Js.null<Firebase.documentReference<keg>>>, // converted to Map.String
}

let placeConverter: Firebase.dataConverter<place, placeConverted> = {
  fromFirestore: (. snapshot, options) => {
    let {createdAt, currency, name, personsAll, taps} = snapshot.data(. options)
    let personsAllMap =
      personsAll
      ->Js.Dict.entries
      ->Belt.Map.String.fromArray
      ->Belt.Map.String.map(((name, recentActivityAt, preferredTap)) => {
        {
          name,
          preferredTap: preferredTap->Null.toOption,
          recentActivityAt,
        }
      })
    let tapsMap = taps->Js.Dict.entries->Belt.Map.String.fromArray
    {createdAt, currency, name, personsAll: personsAllMap, taps: tapsMap}
  },
  toFirestore: (. place, _) => {
    let {createdAt, currency, name, personsAll, taps} = place
    let tapsDict = taps->Belt.Map.String.toArray->Js.Dict.fromArray
    let personsAllDict =
      personsAll
      ->Belt.Map.String.map(personsAllRecordToTuple)
      ->Belt.Map.String.toArray
      ->Js.Dict.fromArray
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
        [Firebase.where("recentConsumptionAt", #">=", firebaseTimestamp)],
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

let usePlaceDocData = (~options=?, placeId) => {
  let firestore = Firebase.useFirestore()
  let placeRef = placeDocumentConverted(firestore, placeId)
  Firebase.useFirestoreDocData(. placeRef, options)
}

let usePlacePersonDocumentStatus = (~options=?, placeId, personId) => {
  let firestore = Firebase.useFirestore()
  let personRef = placePersonDocument(firestore, placeId, personId)
  Firebase.useFirestoreDocData(. personRef, options)
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

type placeUpdate = {
  personsAll?: Belt.Map.String.t<personsAllRecord>,
  taps?: Belt.Map.String.t<Js.null<Firebase.documentReference<keg>>>,
}

let updatePlace = (firestore, placeId, data) => {
  let maybePersonsDict =
    data.personsAll->Option.map(personsAll =>
      personsAll
      ->Belt.Map.String.map(personsAllRecordToTuple)
      ->Belt.Map.String.toArray
      ->Js.Dict.fromArray
    )
  let maybeTapsDict = data.taps->Option.map(taps => {
    taps->Belt.Map.String.toArray->Js.Dict.fromArray
  })
  Firebase.updateDoc(
    placeDocument(firestore, placeId),
    ObjectUtils.omitUndefined({"taps": maybeTapsDict, "personsAll": maybePersonsDict}),
  )
}

let updatePlacePersonsAll = (firestore, placeId, persons: array<(string, personsAllRecord)>) => {
  let updateData = persons->Belt.Array.reduce(Object.empty(), (data, (personId, person)) => {
    ObjectUtils.setIn(Some(data), `personsAll.${personId}`, personsAllRecordToTuple(person))
  })
  Firebase.updateDoc(placeDocument(firestore, placeId), updateData)
}

let addConsumption = (firestore, placeId, kegId, consumption: consumption) => {
  Firebase.updateDoc(
    placeKegDocument(firestore, placeId, kegId),
    {
      "consumptions": Firebase.arrayUnion(consumption),
      "recentConsumptionAt": Firebase.serverTimestamp(),
    },
  )
}

let addPerson = async (firestore, placeId, personName) => {
  let placeSnapshot = await Firebase.getDocFromCache(placeDocument(firestore, placeId))
  let place = placeSnapshot.data(. {})
  let firstTap = place.taps->Js.Dict.keys->Belt.Array.getExn(0)
  let newPerson: FirestoreModels.person = {
    account: Null.null,
    balance: 0,
    createdAt: Firebase.serverTimestamp(),
    name: personName,
    transactions: [],
  }
  let addedPerson = await Firebase.addDoc(placePersonsCollection(firestore, placeId), newPerson)
  let personId = addedPerson.id
  let placeShortcutRecord: personsAllRecord = {
    name: personName,
    preferredTap: Some(firstTap),
    // the nested objects do not support serverTimestamp() :(
    recentActivityAt: Firebase.Timestamp.now(),
  }
  await updatePlacePersonsAll(firestore, placeId, [(personId, placeShortcutRecord)])
}

let deleteConsumption = async (firestore, placeId, kegId, personId, createdAt) => {
  let kegRef = kegDoc(firestore, placeId, kegId)
  let kegSnapshot = await Firebase.getDocFromCache(kegRef)
  let keg = kegSnapshot.data(. {})
  let createMillis = createdAt->Js.Date.getTime
  let newConsumptions =
    keg.consumptions->Belt.Array.keep(c =>
      c.person.id !== personId || c.createdAt->Firebase.Timestamp.toMillis !== createMillis
    )
  let updateData = ObjectUtils.setIn(None, `consumptions`, newConsumptions)
  await Firebase.updateDoc(kegRef, updateData)
}
