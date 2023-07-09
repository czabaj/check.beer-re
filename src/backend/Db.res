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
  balance: int,
  name: string,
  preferredTap: option<string>,
  recentActivityAt: Firebase.Timestamp.t,
}

let personsAllRecordToTuple = (. {
  balance,
  name,
  preferredTap,
  recentActivityAt,
}): FirestoreModels.personsAllItem => (name, recentActivityAt, balance, preferredTap)

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
    let personsAllWithRecord =
      personsAll->Js.Dict.map((. (name, recentActivityAt, balance, preferredTap)) => {
        {
          balance,
          name,
          preferredTap,
          recentActivityAt,
        }
      }, _)
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

type kegConverted = {
  beer: string,
  consumptions: Belt.Map.String.t<consumption>,
  consumptionsSum: int, // added by converter
  createdAt: Firebase.Timestamp.t,
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
    let consumptionsMap = keg.consumptions->Js.Dict.entries->Belt.Map.String.fromArray
    let consumptionsSum =
      consumptionsMap->Belt.Map.String.reduceU(0, (. sum, _, consumption) =>
        sum + consumption.milliliters
      )
    let serialFormatted = "#" ++ keg.serial->Int.toString->String.padStart(3, "0")
    {
      beer: keg.beer,
      consumptions: consumptionsMap,
      consumptionsSum,
      createdAt: keg.createdAt,
      depletedAt: keg.depletedAt,
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
      recentConsumptionAt,
      milliliters,
      price,
      serial,
    } = keg
    let consumptionsDict = consumptions->Belt.Map.String.toArray->Js.Dict.fromArray
    {
      beer,
      consumptions: consumptionsDict,
      createdAt,
      depletedAt,
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

let reactFireOptions: Firebase.reactfireOptions<'a> = {idField: "uid"}

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
        placeKegsCollectionConverted(firestore, placeId),
        [Firebase.where("recentConsumptionAt", #">=", firebaseTimestamp)],
      )
      Firebase.collectionDataRx(query, reactFireOptions)
    }),
  )
}

let kegFirstConsumptionTimestamp = (keg: kegConverted) =>
  keg.consumptions
  ->Belt.Map.String.minKey
  ->Option.flatMap(timestampStr => timestampStr->Float.fromString)

type userConsumption = {milliliters: int, timestamp: float}

let groupKegConsumptionsByUser = (~target=Belt.MutableMap.String.make(), keg: kegConverted) => {
  keg.consumptions->Belt.Map.String.forEach((timestampStr, consumption) => {
    let userCons = {
      timestamp: timestampStr->Float.fromString->Option.getExn,
      milliliters: consumption.milliliters,
    }
    switch Belt.MutableMap.String.get(target, consumption.person.id) {
    | Some(consumptions) => consumptions->Array.push(userCons)
    | None => Belt.MutableMap.String.set(target, consumption.person.id, [userCons])
    }
  })
  target
}

// Hooks

let useCurrentUserAccountDocData = () => {
  Firebase.useObservable(
    ~observableId="currentUser",
    ~source=currentUserAccountRx(Firebase.useAuth(), Firebase.useFirestore()),
  )
}

let usePlacePersonDocumentStatus = (~options=?, placeId, personId) => {
  let firestore = Firebase.useFirestore()
  let personRef = placePersonDocument(firestore, placeId, personId)
  Firebase.useFirestoreDocData(. personRef, options)
}

let useMostRecentKegStatus = placeId => {
  let firestore = Firebase.useFirestore()
  let query = Firebase.query(
    placeKegsCollection(firestore, placeId),
    [Firebase.orderBy("serial", ~direction=#desc), Firebase.limit(1)],
  )
  Firebase.useFirestoreCollectionData(. query, reactFireOptions)
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
    ObjectUtils.setIn(. Some(data), `personsAll.${personId}`, personsAllRecordToTuple(. person))
  })
  Firebase.updateDoc(placeDocument(firestore, placeId), updateData)
}

let addConsumption = (firestore, placeId, kegId, consumption: consumption) => {
  let now = Date.now()
  let updateData = ObjectUtils.setIn(.
    Some({
      "recentConsumptionAt": Firebase.serverTimestamp(),
    }),
    `consumptions.${now->Js.Float.toString}`,
    consumption,
  )
  Firebase.updateDoc(placeKegDocument(firestore, placeId, kegId), updateData)
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
  let updateData = ObjectUtils.setIn(.
    None,
    `consumptions.${consumptionId}`,
    Firebase.deleteField(),
  )
  Firebase.updateDoc(kegRef, updateData)
}

let deletePerson = async (firestore, placeId, personId) => {
  let updatePersonAllData = ObjectUtils.setIn(.
    None,
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
  Firebase.runTransaction(.firestore, async transaction => {
    let kegRef = kegDoc(firestore, placeId, kegId)
    let kegDoc =
      await transaction->Firebase.Transaction.get(kegRef->Firebase.withConterterDoc(kegConverter))
    if !kegDoc.exists(.) {
      Js.Exn.raiseError("Keg not found")
    }
    // untap keg if on tap
    let placeRef = placeDocument(firestore, placeId)
    let placeDoc =
      await transaction->Firebase.Transaction.get(
        placeRef->Firebase.withConterterDoc(placeConverter),
      )
    let place = placeDoc.data(. {})
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
    | Some((tapName, _)) =>
      transaction->Firebase.Transaction.update(
        placeRef,
        ObjectUtils.setIn(. None, `taps.${tapName}`, Firebase.deleteField()),
      )
    | _ => ()
    }
    // create financial transactions in persons documents
    let keg = kegDoc.data(. {})
    let kegPricePerMilliliter = keg.price->Float.fromInt /. keg.consumptionsSum->Float.fromInt
    let nowTimestamp = Firebase.Timestamp.now()
    groupKegConsumptionsByUser(keg)->Belt.MutableMap.String.forEach((personId, consumptions) => {
      let personConsumptionSum =
        consumptions->Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
      let priceShare = (personConsumptionSum->Float.fromInt *. kegPricePerMilliliter)->Int.fromFloat
      let financialTransaction: FirestoreModels.financialTransaction = {
        amount: -1 * priceShare,
        createdAt: nowTimestamp,
        keg: Null.make(kegRef),
        note: Null.null,
      }
      let personRef = placePersonDocument(firestore, placeId, personId)
      transaction->Firebase.Transaction.update(
        personRef,
        {
          "balance": Firebase.incrementInt(-1 * financialTransaction.amount),
          "transactions": Firebase.arrayUnion(financialTransaction),
        },
      )
    })
    // mark keg as depleted
    transaction->Firebase.Transaction.update(kegRef, {"depletedAt": nowTimestamp})
    ()
  })
}
