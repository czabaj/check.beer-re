open FirestoreModels

// Resources

let accountDoc = (firestore, userId): Firebase.documentReference<userAccount> => {
  Firebase.doc(firestore, ~path=`users/${userId}`)
}

let kegDoc = (firestore, placeId, kegId): Firebase.documentReference<keg> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/kegs/${kegId}`)
}

let userAccountsCollection = (firestore): Firebase.collectionReference<userAccount> => {
  Firebase.collection(firestore, ~path="users")
}

@genType
let placeCollection = (firestore): Firebase.collectionReference<place> => {
  Firebase.collection(firestore, ~path="places")
}

@genType
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
  balance: int,
  name: string,
  preferredTap: option<string>,
  recentActivityAt: Firebase.Timestamp.t,
}

let removeLastUndefined: FirestoreModels.personsAllItem => FirestoreModels.personsAllItem = %raw(
  "tuple => tuple.at(-1) === undefined ? tuple.slice(0, -1) : tuple"
)

let personsAllRecordToTuple = (. {
  balance,
  name,
  preferredTap,
  recentActivityAt,
}): FirestoreModels.personsAllItem =>
  removeLastUndefined((name, recentActivityAt, balance, preferredTap))
let personsAllTupleToRecord = (. (name, recentActivityAt, balance, preferredTap)) => {
  balance,
  name,
  preferredTap,
  recentActivityAt,
}

@genType
type placeConverted = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Js.Dict.t<personsAllRecord>, // covert tuple to record
  taps: Js.Dict.t<Js.null<Firebase.documentReference<keg>>>,
}

let placeConverter: Firebase.dataConverter<place, placeConverted> = {
  fromFirestore: (. snapshot, options) => {
    let {createdAt, currency, name, personsAll, taps} = snapshot.data(. options)
    let personsAllWithRecord = personsAll->Js.Dict.map(personsAllTupleToRecord, _)
    {createdAt, currency, name, personsAll: personsAllWithRecord, taps}
  },
  toFirestore: (. place, _) => {
    let {createdAt, currency, name, personsAll, taps} = place
    let parsonsAllTuple = personsAll->Js.Dict.map(personsAllRecordToTuple, _)
    {createdAt, currency, name, personsAll: parsonsAllTuple, taps}
  },
}

let placeDocumentConverted = (firestore, placeId) => {
  placeDocument(firestore, placeId)->Firebase.withConterterDoc(placeConverter)
}

@genType
type kegConverted = {
  beer: string,
  consumptions: Js.Dict.t<consumption>,
  consumptionsSum: int, // added by converter
  createdAt: Firebase.Timestamp.t,
  donors: Js.Dict.t<int>,
  depletedAt: Js.null<Firebase.Timestamp.t>,
  milliliters: int,
  price: int,
  recentConsumptionAt: Js.null<Firebase.Timestamp.t>,
  serial: int,
  serialFormatted: string, // added by converter
}

let kegConverter: Firebase.dataConverter<keg, kegConverted> = {
  fromFirestore: (. snapshot, options) => {
    let keg = snapshot.data(. options)
    let consumptionsSum =
      keg.consumptions
      ->Js.Dict.values
      ->Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
    let serialFormatted = "#" ++ keg.serial->Int.toString->String.padStart(3, "0")
    {
      beer: keg.beer,
      consumptions: keg.consumptions,
      consumptionsSum,
      createdAt: keg.createdAt,
      depletedAt: keg.depletedAt,
      donors: keg.donors,
      recentConsumptionAt: keg.recentConsumptionAt,
      milliliters: keg.milliliters,
      price: keg.price,
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
      donors,
      recentConsumptionAt,
      milliliters,
      price,
      serial,
    } = keg
    {
      beer,
      consumptions,
      createdAt,
      depletedAt,
      donors,
      milliliters,
      price,
      recentConsumptionAt,
      serial,
    }
  },
}

let placeKegsCollectionConverted = (firestore, placeId) => {
  placeKegsCollection(firestore, placeId)->Firebase.withConterterCollection(kegConverter)
}

// Queries and helpers

let getUid: 'a => option<string> = %raw("data => data?.uid")

let currentUserAccountQuery = (firestore, user: Firebase.User.t) => {
  Firebase.query(
    userAccountsCollection(firestore),
    [Firebase.where("email", #"==", user.email), Firebase.limit(1)],
  )
}

let currentUserAccountRx = (auth, firestore) => {
  Rxfire.Auth.user(auth)->Rxjs.pipe4(
    Rxjs.switchMap(user => {
      switch Js.Nullable.toOption(user) {
      | None => Rxjs.fromArray([])
      | Some(user) => {
          let query = currentUserAccountQuery(firestore, user)
          Rxfire.Firestore.collectionData(query)
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

let recentlyFinishedKegsRx = (firestore, placeId) => {
  slidingWindowRx->Rxjs.pipe(
    Rxjs.switchMap(_slidingWindow => {
      let now = Js.Date.make()
      let monthAgo = Js.Date.setMonth(now, Js.Date.getMonth(now) -. 1.0)
      let firebaseTimestamp = Firebase.Timestamp.fromMillis(monthAgo)
      let query = Firebase.query(
        placeKegsCollectionConverted(firestore, placeId),
        [Firebase.where("depletedAt", #">=", firebaseTimestamp)],
      )
      Rxfire.Firestore.collectionData(query)
    }),
  )
}

let kegFirstConsumptionTimestamp = (keg: kegConverted) =>
  keg.consumptions
  ->Js.Dict.keys
  ->Array.reduce(None, (min, timestampStr) =>
    switch min {
    | Some(minTimestampStr) =>
      timestampStr->String.localeCompare(minTimestampStr) < 0.0 ? Some(timestampStr) : min
    | None => Some(timestampStr)
    }
  )
  ->Option.flatMap(timestampStr => timestampStr->Float.fromString)

type userConsumption = {
  consumptionId: string,
  kegId: string,
  beer: string,
  milliliters: int,
  createdAt: Js.Date.t,
}

let groupKegConsumptionsByUser = (~target=Belt.MutableMap.String.make(), keg: kegConverted) => {
  keg.consumptions
  ->Js.Dict.entries
  ->Array.forEach(((timestampStr, consumption)) => {
    let userCons = {
      consumptionId: timestampStr,
      kegId: getUid(keg)->Option.getExn,
      beer: keg.beer,
      milliliters: consumption.milliliters,
      createdAt: timestampStr->Float.fromString->Option.getExn->Js.Date.fromFloat,
    }
    switch Belt.MutableMap.String.get(target, consumption.person.id) {
    | Some(consumptions) => consumptions->Array.push(userCons)
    | None => Belt.MutableMap.String.set(target, consumption.person.id, [userCons])
    }
  })
  target
}

let allChargedKegsRx = (firestore, placeId) => {
  let chargedKegsQuery = Firebase.query(
    placeKegsCollectionConverted(firestore, placeId),
    [
      Firebase.where("depletedAt", #"==", null),
      // limit to 50 to avoid expensive calls, but 50 kegs on stock is a lot
      Firebase.limit(50),
    ],
  )
  Rxfire.Firestore.collectionData(chargedKegsQuery)
}

// Hooks

let useCurrentUserAccountDocData = () => {
  Reactfire.useObservable(
    ~observableId="currentUser",
    ~source=currentUserAccountRx(Reactfire.useAuth(), Reactfire.useFirestore()),
  )
}

let usePlacePersonDocumentStatus = (~options=?, placeId, personId) => {
  let firestore = Reactfire.useFirestore()
  let personRef = placePersonDocument(firestore, placeId, personId)
  Reactfire.useFirestoreDocDataWithOptions(personRef, ~options)
}

let useMostRecentKegStatus = placeId => {
  let firestore = Reactfire.useFirestore()
  let query = Firebase.query(
    placeKegsCollection(firestore, placeId),
    [Firebase.orderBy("serial", ~direction=#desc), Firebase.limit(1)],
  )
  Reactfire.useFirestoreCollectionData(query)
}

// Mutations

type placeUpdate = {
  personsAll?: Js.Dict.t<personsAllRecord>,
  taps?: Js.Dict.t<Js.null<Firebase.documentReference<keg>>>,
}

let updatePlace = (firestore, placeId, data) => {
  let maybePersonsDict = data.personsAll->Option.map(Js.Dict.map(personsAllRecordToTuple, _))
  Firebase.updateDoc(
    placeDocument(firestore, placeId),
    ObjectUtils.omitUndefined({"taps": data.taps, "personsAll": maybePersonsDict}),
  )
}

let updatePlacePersonsAll = (firestore, placeId, persons: array<(string, personsAllRecord)>) => {
  let updateData = persons->Belt.Array.reduce(Object.empty(), (data, (personId, person)) => {
    ObjectUtils.setIn(data, `personsAll.${personId}`, personsAllRecordToTuple(. person))
  })
  Firebase.updateDoc(placeDocument(firestore, placeId), updateData)
}

let addConsumption = (firestore, placeId, kegId, consumption: consumption) => {
  let now = Date.now()
  let updateData = ObjectUtils.setIn(
    {
      "recentConsumptionAt": Firebase.serverTimestamp(),
    },
    `consumptions.${now->Js.Float.toString}`,
    consumption,
  )
  Firebase.updateDoc(placeKegDocument(firestore, placeId, kegId), updateData)
}

let addFinancialTransaction = async (
  firestore,
  placeId,
  personId,
  transaction: FirestoreModels.financialTransaction,
) => {
  let placeRef = placeDocument(firestore, placeId)
  let placeData = (await Firebase.getDocFromCache(placeRef)).data(. {})
  let personsAllTuple = placeData.personsAll->Js.Dict.get(personId)->Option.getExn
  let personsAllRecord = personsAllTupleToRecord(. personsAllTuple)
  let newPersonsAllRecord = {
    ...personsAllRecord,
    balance: personsAllRecord.balance + transaction.amount,
  }
  let updatePlaceData = ObjectUtils.setIn(
    Object.empty(),
    `personsAll.${personId}`,
    personsAllRecordToTuple(. newPersonsAllRecord),
  )
  await Firebase.writeBatch(firestore)
  ->Firebase.WriteBatch.update(
    placePersonDocument(firestore, placeId, personId),
    {
      "transactions": Firebase.arrayUnion([transaction]),
    },
  )
  ->Firebase.WriteBatch.update(placeRef, updatePlaceData)
  ->Firebase.WriteBatch.commit
}

let addPerson = async (firestore, placeId, personName) => {
  let placeSnapshot = await Firebase.getDocFromCache(placeDocument(firestore, placeId))
  let place = placeSnapshot.data(. {})
  let firstTap = place.taps->Js.Dict.keys->Belt.Array.getExn(0)
  let newPerson: FirestoreModels.person = {
    account: Null.null,
    createdAt: Firebase.serverTimestamp(),
    name: personName,
    transactions: [],
  }
  let addedPerson = await Firebase.addDoc(placePersonsCollection(firestore, placeId), newPerson)
  let personId = addedPerson.id
  let placeShortcutRecord: personsAllRecord = {
    balance: 0,
    name: personName,
    preferredTap: Some(firstTap),
    // the nested objects do not support serverTimestamp() :(
    recentActivityAt: Firebase.Timestamp.now(),
  }
  await updatePlacePersonsAll(firestore, placeId, [(personId, placeShortcutRecord)])
}

let deleteConsumption = (firestore, placeId, kegId, consumptionId) => {
  let kegRef = kegDoc(firestore, placeId, kegId)
  let updateData = ObjectUtils.setIn(
    Object.empty(),
    `consumptions.${consumptionId}`,
    Firebase.deleteField(),
  )
  Firebase.updateDoc(kegRef, updateData)
}

let deletePerson = async (firestore, placeId, personId) => {
  let updatePersonAllData = ObjectUtils.setIn(
    Object.empty(),
    `personsAll.${personId}`,
    Firebase.deleteField(),
  )
  await Firebase.updateDoc(placeDocument(firestore, placeId), updatePersonAllData)
  await Firebase.deleteDoc(placePersonDocument(firestore, placeId, personId))
}

let deleteKeg = async (firestore, placeId, kegId) => {
  let kegRef = kegDoc(firestore, placeId, kegId)
  await Firebase.deleteDoc(kegRef)
}

let finalizeKeg = async (firestore, placeId, kegId) => {
  let batch = Firebase.writeBatch(firestore)
  let kegRef = kegDoc(firestore, placeId, kegId)
  let keg = (
    await Firebase.getDocFromCache(kegRef->Firebase.withConterterDoc(kegConverter))
  ).data(. {})
  let placeRef = placeDocument(firestore, placeId)
  let place = (
    await Firebase.getDocFromCache(placeRef->Firebase.withConterterDoc(placeConverter))
  ).data(. {})
  let placeUpdateObject = Object.empty()
  // untap keg if on tap
  let kegOnTap =
    place.taps
    ->Js.Dict.entries
    ->Array.find(((_, maybeKegRef)) =>
      maybeKegRef
      ->Null.toOption
      ->Option.map(kegRef => kegRef.id === kegId)
      ->Option.getWithDefault(false)
    )
  switch kegOnTap {
  | Some((tapName, _)) => placeUpdateObject->Object.set(`taps.${tapName}`, Firebase.deleteField())
  | _ => ()
  }
  // create financial transactions for consumptions
  let kegPricePerMilliliter = keg.price->Float.fromInt /. keg.consumptionsSum->Float.fromInt
  let nowTimestamp = Firebase.Timestamp.now()
  let personsTransactions = Belt.MutableMap.String.make()
  groupKegConsumptionsByUser(keg)->Belt.MutableMap.String.forEach((personId, consumptions) => {
    let personConsumptionSum =
      consumptions->Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
    let priceShare = (personConsumptionSum->Float.fromInt *. kegPricePerMilliliter)->Int.fromFloat
    let financialTransaction: FirestoreModels.financialTransaction = {
      amount: -1 * priceShare,
      createdAt: nowTimestamp,
      keg: Null.make(keg.serial),
      note: Null.null,
    }
    personsTransactions->Belt.MutableMap.String.set(personId, [financialTransaction])
  })
  // create financial transaction for deposit of the keg
  keg.donors
  ->Js.Dict.entries
  ->Array.forEach(((personId, amount)) => {
    let financialTransaction: FirestoreModels.financialTransaction = {
      amount,
      createdAt: nowTimestamp,
      keg: Null.make(keg.serial),
      note: Null.null,
    }
    switch personsTransactions->Belt.MutableMap.String.get(personId) {
    | None => personsTransactions->Belt.MutableMap.String.set(personId, [financialTransaction])
    | Some(transactions) => transactions->Array.push(financialTransaction)
    }
  })
  // write financial transactions to person documents and make personsAll updates
  personsTransactions->Belt.MutableMap.String.forEach((personId, transactions) => {
    let personRef = placePersonDocument(firestore, placeId, personId)
    batch
    ->Firebase.WriteBatch.update(
      personRef,
      {
        "transactions": Firebase.arrayUnion(transactions),
      },
    )
    ->ignore
    let transactiuonsSum =
      transactions->Array.reduce(0, (sum, transaction) => sum + transaction.amount)
    let personsAllRecord = place.personsAll->Js.Dict.get(personId)->Option.getExn
    let newPersonsAllRecord = {
      ...personsAllRecord,
      balance: personsAllRecord.balance + transactiuonsSum,
    }
    placeUpdateObject->Object.set(
      `personsAll.${personId}`,
      personsAllRecordToTuple(. newPersonsAllRecord),
    )
  })
  await batch
  ->Firebase.WriteBatch.update(placeRef, placeUpdateObject)
  // mark keg as depleted
  ->Firebase.WriteBatch.update(kegRef, {"depletedAt": nowTimestamp})
  ->Firebase.WriteBatch.commit
}
