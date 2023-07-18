open FirestoreModels

// Resources

let kegDoc = (firestore, placeId, kegId): Firebase.documentReference<keg> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/kegs/${kegId}`)
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

@genType
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
  users: Js.Dict.t<int>,
}

let placeConverter: Firebase.dataConverter<place, placeConverted> = {
  fromFirestore: (. snapshot, options) => {
    let {createdAt, currency, name, personsAll, taps, users} = snapshot.data(. options)
    let personsAllWithRecord = personsAll->Js.Dict.map(personsAllTupleToRecord, _)
    {createdAt, currency, name, personsAll: personsAllWithRecord, taps, users}
  },
  toFirestore: (. place, _) => {
    let {createdAt, currency, name, personsAll, taps, users} = place
    let parsonsAllTuple = personsAll->Js.Dict.map(personsAllRecordToTuple, _)
    {createdAt, currency, name, personsAll: parsonsAllTuple, taps, users}
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

let getUid: 'a => string = %raw("data => data?.uid")

let placesByUserIdRx = (firestore, userId) => {
  let query = Firebase.query(
    placeCollection(firestore),
    [Firebase.where(`users.${userId}`, #">=", 0)],
  )
  Rxfire.collectionData(query)
}

let slidingWindowRx = Rxjs.interval(60 * 60 * 1000)->Rxjs.pipe3(
  Rxjs.startWith(0),
  Rxjs.map((_, _) => {
    let now = Js.Date.make()
    let monthAgo = Js.Date.setMonth(now, Js.Date.getMonth(now) -. 1.0)
    Firebase.Timestamp.fromMillis(monthAgo)
  }),
  Rxjs.shareReplay(1),
)

let recentlyFinishedKegsRx = (firestore, placeId) => {
  slidingWindowRx->Rxjs.pipe(
    Rxjs.switchMap(monthAgo => {
      let query = Firebase.query(
        placeKegsCollectionConverted(firestore, placeId),
        [Firebase.where("depletedAt", #">=", monthAgo)],
      )
      Rxfire.collectionData(query)
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

let groupKegConsumptionsByUser = (~target=Map.make(), keg: kegConverted) => {
  keg.consumptions
  ->Js.Dict.entries
  ->Array.forEach(((timestampStr, consumption)) => {
    let userCons = {
      consumptionId: timestampStr,
      kegId: getUid(keg),
      beer: keg.beer,
      milliliters: consumption.milliliters,
      createdAt: timestampStr->Float.fromString->Option.getExn->Js.Date.fromFloat,
    }
    switch Map.get(target, consumption.person.id) {
    | Some(consumptions) => consumptions->Array.push(userCons)
    | None => Map.set(target, consumption.person.id, [userCons])
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
  Rxfire.collectionData(chargedKegsQuery)
}

// Hooks

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

module Keg = {
  @genType
  let finalizeGetUpdateObjects = (keg: kegConverted, place: placeConverted) => {
    let kegId = getUid(keg)
    let nowTimestamp = Firebase.Timestamp.now()
    let kegUpdataObject = {"depletedAt": nowTimestamp}
    let personsUpdateObjects = Map.make()
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
    let donorsEntries = keg.donors->Js.Dict.entries
    let kegDonorPrice = donorsEntries->Array.reduce(0, (price, (_, amount)) => price + amount)
    let kegPricePerMilliliter = kegDonorPrice->Float.fromInt /. keg.consumptionsSum->Float.fromInt
    let personsTransactions = Map.make()
    groupKegConsumptionsByUser(keg)->Map.forEachWithKey((consumptions, personId) => {
      let personConsumptionSum =
        consumptions->Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
      let priceShare = (personConsumptionSum->Float.fromInt *. kegPricePerMilliliter)->Int.fromFloat
      let financialTransaction: FirestoreModels.financialTransaction = {
        amount: -1 * priceShare,
        createdAt: nowTimestamp,
        keg: Null.make(keg.serial),
        note: Null.null,
      }
      personsTransactions->Map.set(personId, [financialTransaction])
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
      switch personsTransactions->Map.get(personId) {
      | None => personsTransactions->Map.set(personId, [financialTransaction])
      | Some(transactions) => transactions->Array.push(financialTransaction)
      }
    })
    // write financial transactions to person documents and make personsAll updates
    personsTransactions->Map.forEachWithKey((transactions, personId) => {
      personsUpdateObjects->Map.set(
        personId,
        {
          "transactions": Firebase.arrayUnion(transactions),
        },
      )
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
    (kegUpdataObject, personsUpdateObjects, placeUpdateObject)
  }
  let finalize = async (firestore, placeId, kegId) => {
    let kegRef = kegDoc(firestore, placeId, kegId)
    let keg = (
      await Firebase.getDocFromCache(kegRef->Firebase.withConterterDoc(kegConverter))
    ).data(. {})
    let placeRef = placeDocument(firestore, placeId)
    let place = (
      await Firebase.getDocFromCache(placeRef->Firebase.withConterterDoc(placeConverter))
    ).data(. {})
    let (kegUpdataObject, personsUpdateObjects, placeUpdateObject) = finalizeGetUpdateObjects(
      keg,
      place,
    )
    let batch = Firebase.writeBatch(firestore)
    personsUpdateObjects->Map.forEachWithKey((personUpdateObject, personId) =>
      batch
      ->Firebase.WriteBatch.update(
        placePersonDocument(firestore, placeId, personId),
        personUpdateObject,
      )
      ->ignore
    )
    await batch
    ->Firebase.WriteBatch.update(placeRef, placeUpdateObject)
    ->Firebase.WriteBatch.update(kegRef, kegUpdataObject)
    ->Firebase.WriteBatch.commit
  }
}

module Place = {
  let add = async (firestore, ~personName, ~placeName, ~userId) => {
    let placeDoc = Firebase.seedDoc(placeCollection(firestore))
    let personDoc = Firebase.seedDoc(placePersonsCollection(firestore, placeDoc.id))
    let defaultTapName = "Pípa"
    let now = Firebase.Timestamp.now()
    let personTuple = personsAllRecordToTuple(. {
      balance: 0,
      name: personName,
      preferredTap: Some(defaultTapName),
      recentActivityAt: now,
    })
    await Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.set(
      placeDoc,
      {
        createdAt: now,
        currency: "CZK",
        name: placeName,
        personsAll: Dict.fromArray([(personDoc.id, personTuple)]),
        taps: Dict.fromArray([(defaultTapName, Null.null)]),
        users: Dict.fromArray([(userId, FirestoreModels.roleToJs(FirestoreModels.Owner))]),
      },
      {},
    )
    ->Firebase.WriteBatch.set(
      personDoc,
      {
        account: Js.Null.return(userId),
        createdAt: now,
        name: personName,
        transactions: [],
      },
      {},
    )
    ->Firebase.WriteBatch.commit
    placeDoc
  }
  let tapAdd = (firestore, ~placeId, ~tapName) => {
    let placeRef = placeDocument(firestore, placeId)
    let updateObject = Object.empty()
    updateObject->Object.set(`taps.${tapName}`, Null.null)
    Firebase.updateDoc(placeRef, updateObject)
  }
  let tapDelete = (firestore, ~placeId, ~tapName) => {
    let placeRef = placeDocument(firestore, placeId)
    let updateObject = Object.empty()
    updateObject->Object.set(`taps.${tapName}`, Firebase.deleteField())
    Firebase.updateDoc(placeRef, updateObject)
  }
  let tapRename = async (firestore, ~placeId, ~currentName, ~newName) => {
    let placeRef = placeDocumentConverted(firestore, placeId)
    let place = (await Firebase.getDocFromCache(placeRef)).data(. {})
    let currentValue = place.taps->Js.Dict.unsafeGet(currentName)
    let updateObject = Object.empty()
    let newTaps = place.taps->Dict.copy
    newTaps->Dict.delete(currentName)
    newTaps->Dict.set(newName, currentValue)
    updateObject->Object.set("taps", newTaps)
    place.personsAll
    ->Dict.toArray
    ->Array.forEach(((personId, person)) => {
      switch person.preferredTap {
      | None => ()
      | Some(preferredTap) =>
        if preferredTap === currentName {
          updateObject->Object.set(
            `personsAll.${personId}`,
            personsAllRecordToTuple(. {
              ...person,
              preferredTap: Some(newName),
            }),
          )
        }
      }
    })
    await Firebase.updateDoc(placeRef, updateObject)
  }
  let tapKegOff = (firestore, ~placeId, ~tapName) => {
    let placeRef = placeDocument(firestore, placeId)
    let updateObject = Object.empty()
    updateObject->Object.set(`taps.${tapName}`, Null.null)
    Firebase.updateDoc(placeRef, updateObject)
  }
  let tapKegOn = (firestore, ~placeId, ~tapName, ~kegId) => {
    let placeRef = placeDocument(firestore, placeId)
    let kegRef = kegDoc(firestore, placeId, kegId)
    let updateObject = Object.empty()
    updateObject->Object.set(`taps.${tapName}`, kegRef)
    Firebase.updateDoc(placeRef, updateObject)
  }
}
