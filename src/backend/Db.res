open FirestoreModels

// Resources

let kegDoc = (firestore, placeId, kegId): Firebase.documentReference<keg> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/kegs/${kegId}`)
}

@genType
let placeCollection = (firestore): Firebase.collectionReference<place> => {
  Firebase.collection(firestore, ~path="places")
}

let personsIndexDocument = (firestore, placeId): Firebase.documentReference<personsIndex> => {
  Firebase.doc(firestore, ~path=`places/${placeId}/personsIndex/1`)
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
  userId: Js.Null.t<string>,
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
  userId,
}): FirestoreModels.personsAllItem =>
  removeLastUndefined((name, recentActivityAt, balance, userId, preferredTap))

let personsAllTupleToRecord = (. (name, recentActivityAt, balance, userId, preferredTap)) => {
  balance,
  name,
  preferredTap,
  recentActivityAt,
  userId,
}

@genType
type personsIndexConverted = {all: Js.Dict.t<personsAllRecord>}

let personsIndexConverter: Firebase.dataConverter<personsIndex, personsIndexConverted> = {
  fromFirestore: (. snapshot, options) => {
    let {all} = snapshot.data(. options)
    let allWithRecord = all->Js.Dict.map(personsAllTupleToRecord, _)
    {all: allWithRecord}
  },
  toFirestore: (. place, _) => {
    let {all} = place
    let allWithTuple = all->Js.Dict.map(personsAllRecordToTuple, _)
    {all: allWithTuple}
  },
}

let personsIndexConverted = (firestore, placeId) => {
  personsIndexDocument(firestore, placeId)->Firebase.withConterterDoc(personsIndexConverter)
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

let formatKegSerial = (serial: int) => "#" ++ serial->Int.toString->String.padStart(3, "0")

let kegConverter: Firebase.dataConverter<keg, kegConverted> = {
  fromFirestore: (. snapshot, options) => {
    let keg = snapshot.data(. options)
    let consumptionsSum =
      keg.consumptions
      ->Js.Dict.values
      ->Array.reduce(0, (sum, consumption) => sum + consumption.milliliters)
    let serialFormatted = formatKegSerial(keg.serial)
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

module Keg = {
  let addConsumption = async (
    firestore,
    ~consumption: FirestoreModels.consumption,
    ~kegId,
    ~personId,
    ~placeId,
  ) => {
    let now = Date.now()
    let kegRef = placeKegDocument(firestore, placeId, kegId)
    let updateKegData = ObjectUtils.setIn(
      {
        "recentConsumptionAt": Firebase.serverTimestamp(),
      },
      `consumptions.${now->Js.Float.toString}`,
      consumption,
    )
    let personsIndexRef = personsIndexDocument(firestore, placeId)
    let personsIndex = (await Firebase.getDocFromCache(personsIndexRef)).data(. {})
    let personRecord = personsIndex.all->Js.Dict.unsafeGet(personId)->personsAllTupleToRecord(. _)
    let personsIndexUpdateData = Object.empty()
    personsIndexUpdateData->Object.set(
      `all.${personId}`,
      personsAllRecordToTuple(. {
        ...personRecord,
        recentActivityAt: Firebase.Timestamp.now(),
      }),
    )
    Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.update(kegRef, updateKegData)
    ->Firebase.WriteBatch.update(personsIndexRef, personsIndexUpdateData)
    ->Firebase.WriteBatch.commit
  }
  let delete = (firestore, ~placeId, ~kegId) => {
    let kegRef = kegDoc(firestore, placeId, kegId)
    Firebase.deleteDoc(kegRef)
  }
  let deleteConsumption = (firestore, ~placeId, ~kegId, ~consumptionId) => {
    let kegRef = kegDoc(firestore, placeId, kegId)
    let updateData = ObjectUtils.setIn(
      Object.empty(),
      `consumptions.${consumptionId}`,
      Firebase.deleteField(),
    )
    Firebase.updateDoc(kegRef, updateData)
  }
  @genType
  let finalizeGetUpdateObjects = (
    keg: kegConverted,
    place: place,
    personsIndex: personsIndexConverted,
  ) => {
    let kegId = getUid(keg)
    let nowTimestamp = Firebase.Timestamp.now()
    let kegUpdataObject = {"depletedAt": nowTimestamp}
    let personsUpdateObjects = Map.make()
    let personsIndexUpdateObject = Object.empty()
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
    | Some((tapName, _)) => placeUpdateObject->Object.set(`taps.${tapName}`, Null.null)
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
        person: Null.null,
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
        person: Null.null,
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
      let personsAllRecord = personsIndex.all->Js.Dict.get(personId)->Option.getExn
      let newPersonsAllRecord = {
        ...personsAllRecord,
        balance: personsAllRecord.balance + transactiuonsSum,
      }
      personsIndexUpdateObject->Object.set(
        `all.${personId}`,
        personsAllRecordToTuple(. newPersonsAllRecord),
      )
    })
    (kegUpdataObject, personsUpdateObjects, placeUpdateObject, personsIndexUpdateObject)
  }
  let finalize = async (firestore, placeId, kegId) => {
    let kegRef = kegDoc(firestore, placeId, kegId)->Firebase.withConterterDoc(kegConverter)
    let keg = (await Firebase.getDocFromCache(kegRef)).data(. {})
    let placeRef = placeDocument(firestore, placeId)
    let place = (await Firebase.getDocFromCache(placeRef)).data(. {})
    let personsIndexRef = personsIndexDocument(firestore, placeId)
    let personsIndex = (
      await Firebase.getDocFromCache(
        personsIndexRef->Firebase.withConterterDoc(personsIndexConverter),
      )
    ).data(. {})
    let (
      kegUpdataObject,
      personsUpdateObjects,
      placeUpdateObject,
      personsIndexUpdateObject,
    ) = finalizeGetUpdateObjects(keg, place, personsIndex)
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
    ->Firebase.WriteBatch.update(personsIndexRef, personsIndexUpdateObject)
    ->Firebase.WriteBatch.update(kegRef, kegUpdataObject)
    ->Firebase.WriteBatch.commit
  }
}

module Place = {
  let add = async (firestore, ~personName, ~placeName, ~userId) => {
    let placeDoc = Firebase.seedDoc(placeCollection(firestore))
    let personDoc = Firebase.seedDoc(placePersonsCollection(firestore, placeDoc.id))
    let personsIndexDoc = personsIndexDocument(firestore, placeDoc.id)
    let defaultTapName = "Pípa"
    let now = Firebase.Timestamp.now()
    let personTuple = personsAllRecordToTuple(. {
      balance: 0,
      name: personName,
      preferredTap: Some(defaultTapName),
      recentActivityAt: now,
      userId: Js.Null.return(userId),
    })
    await Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.set(
      placeDoc,
      {
        createdAt: now,
        currency: "CZK",
        name: placeName,
        taps: Dict.fromArray([(defaultTapName, Null.null)]),
        users: Dict.fromArray([(userId, FirestoreModels.roleToJs(FirestoreModels.Owner))]),
      },
      {},
    )
    ->Firebase.WriteBatch.set(
      personDoc,
      {
        createdAt: now,
        transactions: [],
      },
      {},
    )
    ->Firebase.WriteBatch.set(
      personsIndexDoc,
      {
        all: Dict.fromArray([(personDoc.id, personTuple)]),
      },
      {},
    )
    ->Firebase.WriteBatch.commit
    placeDoc
  }
  let delete = (firestore, ~placeId) => {
    let placeRef = placeDocument(firestore, placeId)
    Firebase.deleteDoc(placeRef)
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
    let personsIndexRef = personsIndexConverted(firestore, placeId)
    let personsIndex = (await Firebase.getDocFromCache(personsIndexRef)).data(. {})
    let placeRef = placeDocument(firestore, placeId)
    let place = (await Firebase.getDocFromCache(placeRef)).data(. {})
    let currentValue = place.taps->Js.Dict.unsafeGet(currentName)
    let placeUpdateObject = Object.empty()
    let personsIndexUpdateObject = Object.empty()
    let newTaps = place.taps->Dict.copy
    newTaps->Dict.delete(currentName)
    newTaps->Dict.set(newName, currentValue)
    placeUpdateObject->Object.set("taps", newTaps)
    personsIndex.all
    ->Dict.toArray
    ->Array.forEach(((personId, person)) => {
      switch person.preferredTap {
      | None => ()
      | Some(preferredTap) =>
        if preferredTap === currentName {
          personsIndexUpdateObject->Object.set(
            `all.${personId}`,
            personsAllRecordToTuple(. {
              ...person,
              preferredTap: Some(newName),
            }),
          )
        }
      }
    })
    await Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.update(placeRef, placeUpdateObject)
    ->Firebase.WriteBatch.update(personsIndexRef, personsIndexUpdateObject)
    ->Firebase.WriteBatch.commit
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
  let update = (firestore, ~placeId, ~createdAt: Firebase.Timestamp.t, ~name: string) => {
    let placeDoc = placeDocument(firestore, placeId)
    Firebase.updateDoc(placeDoc, {"createdAt": createdAt, "name": name})
  }
}

module Person = {
  let add = async (firestore, ~placeId, ~personName) => {
    let placeSnapshot = await Firebase.getDocFromCache(placeDocument(firestore, placeId))
    let place = placeSnapshot.data(. {})
    let firstTap = place.taps->Js.Dict.keys->Belt.Array.getExn(0)
    let now = Firebase.Timestamp.now()
    let personDoc = Firebase.seedDoc(placePersonsCollection(firestore, placeId))
    let newPerson: FirestoreModels.person = {
      createdAt: now,
      transactions: [],
    }
    let newPersonsAllRecord = {
      balance: 0,
      name: personName,
      preferredTap: Some(firstTap),
      recentActivityAt: now,
      userId: Null.null,
    }
    let updatePersonsIndexData = ObjectUtils.setIn(
      Object.empty(),
      `all.${personDoc.id}`,
      personsAllRecordToTuple(. newPersonsAllRecord),
    )
    await Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.set(personDoc, newPerson, {})
    ->Firebase.WriteBatch.update(personsIndexDocument(firestore, placeId), updatePersonsIndexData)
    ->Firebase.WriteBatch.commit
  }
  let addFinancialTransaction = async (
    firestore,
    ~placeId,
    ~personId,
    ~counterPartyId,
    ~transaction: FirestoreModels.financialTransaction,
  ) => {
    let personsIndexRef = personsIndexDocument(firestore, placeId)
    let personsIndex = (await Firebase.getDocFromCache(personsIndexRef)).data(. {})
    let personsAllTuple = personsIndex.all->Js.Dict.get(personId)->Option.getExn
    let personsAllRecord = personsAllTupleToRecord(. personsAllTuple)
    let newPersonsAllRecord = {
      ...personsAllRecord,
      balance: personsAllRecord.balance + transaction.amount,
    }
    let updatePersonsIndexData = Object.empty()
    updatePersonsIndexData->Object.set(
      `all.${personId}`,
      personsAllRecordToTuple(. newPersonsAllRecord),
    )
    let counterPartyTuple = personsIndex.all->Js.Dict.get(counterPartyId)->Option.getExn
    let counterPartyRecord = personsAllTupleToRecord(. counterPartyTuple)
    let newCounterPartyRecord = {
      ...counterPartyRecord,
      balance: counterPartyRecord.balance - transaction.amount,
    }
    updatePersonsIndexData->Object.set(
      `all.${counterPartyId}`,
      personsAllRecordToTuple(. newCounterPartyRecord),
    )
    let counterPartyTransaction: FirestoreModels.financialTransaction = {
      ...transaction,
      amount: -1 * transaction.amount,
      keg: Null.null,
      person: Null.make(personId),
    }
    await Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.update(
      placePersonDocument(firestore, placeId, personId),
      {
        "transactions": Firebase.arrayUnion([transaction]),
      },
    )
    ->Firebase.WriteBatch.update(
      placePersonDocument(firestore, placeId, counterPartyId),
      {
        "transactions": Firebase.arrayUnion([counterPartyTransaction]),
      },
    )
    ->Firebase.WriteBatch.update(personsIndexRef, updatePersonsIndexData)
    ->Firebase.WriteBatch.commit
  }
  let delete = (firestore, ~placeId, ~personId) => {
    let personRef = placePersonDocument(firestore, placeId, personId)
    let personsIndexRef = personsIndexDocument(firestore, placeId)
    let updatePersonIndexData = Object.empty()
    updatePersonIndexData->Object.set(`all.${personId}`, Firebase.deleteField())
    Firebase.writeBatch(firestore)
    ->Firebase.WriteBatch.delete(personRef)
    ->Firebase.WriteBatch.update(personsIndexRef, updatePersonIndexData)
    ->Firebase.WriteBatch.commit
  }
}

module PersonsIndex = {
  let allEntriesSortedRx = (firestore, ~placeId) => {
    let personsIndexRef = personsIndexConverted(firestore, placeId)
    Rxfire.docData(personsIndexRef)->Rxjs.pipe2(
      Rxjs.keepSome,
      Rxjs.map((personsIndex: personsIndexConverted, _) => {
        let personsAllEntries = personsIndex.all->Js.Dict.entries
        personsAllEntries->Array.sort(((_, a), (_, b)) => {
          a.name->Js.String2.localeCompare(b.name)
        })
        personsAllEntries
      }),
    )
  }
  let update = (firestore, ~placeId, ~personsChanges: array<(string, personsAllRecord)>) => {
    let personsIndexRef = personsIndexDocument(firestore, placeId)
    let updateObject = Object.empty()
    personsChanges->Array.forEach(((personId, person)) => {
      updateObject->Object.set(`all.${personId}`, personsAllRecordToTuple(. person))
    })
    Firebase.updateDoc(personsIndexRef, updateObject)
  }
}

module ShareLink = {
  let collection = (firestore): Firebase.collectionReference<shareLink> =>
    Firebase.collection(firestore, ~path="shareLinks")

  let document = (firestore, linkId): Firebase.documentReference<shareLink> => {
    Firebase.doc(firestore, ~path=`shareLinks/${linkId}`)
  }

  let delete = (firestore, ~linkId) => {
    let shareLinkDocument = document(firestore, linkId)
    Firebase.deleteDoc(shareLinkDocument)
  }

  let upsert = async (firestore, ~placeId, ~personId, ~role) => {
    if role === FirestoreModels.Owner {
      Exn.raiseError("Changing owner is currently not supported")
    }
    let shareLinkCollection = collection(firestore)
    open Firebase
    let shareLinkQuery = query(
      shareLinkCollection,
      [where("person", #"==", personId), where("place", #"==", placeId), limit(1)],
    )
    let shareLinks = await getDocs(shareLinkQuery)
    switch shareLinks.docs {
    | [shareLinkSnapshot] => {
        await updateDoc(
          shareLinkSnapshot.ref,
          {"createdAt": Timestamp.now(), "role": role->roleToJs},
        )
        shareLinkSnapshot.id
      }
    | _ =>
      let newDoc = await addDoc(
        shareLinkCollection,
        {createdAt: Timestamp.now(), person: personId, place: placeId, role: role->roleToJs},
      )
      newDoc.id
    }
  }

  // this method uses transaction, thus requures the user to be online
  let acceptInvitation = (firestore, ~linkId, ~userId) => {
    let shareLinkDocument = document(firestore, linkId)
    open Firebase
    runTransaction(.firestore, async transaction => {
      let shareLinkSnapshot = await transaction->Transaction.get(shareLinkDocument)
      if !shareLinkSnapshot.exists(.) {
        Exn.raiseError("Share link does not exist")
      }
      let {place, person, role} = shareLinkSnapshot.data(. {})
      let placeIndexDocument = personsIndexConverted(firestore, place)
      let placeIndex = (await transaction->Transaction.get(placeIndexDocument)).data(. {})
      let userAlreadyInPlace =
        placeIndex.all
        ->Dict.valuesToArray
        ->Array.some(p => p.userId->Null.mapWithDefault(false, id => id === userId))
      if userAlreadyInPlace {
        Exn.raiseError("User already in place")
      }
      let personRecord = placeIndex.all->Js.Dict.get(person)->Option.getExn
      if personRecord.userId !== Null.null {
        Exn.raiseError("Person already has a connected user account")
      }
      // update personsIndex - add userId to person tuple
      let newPersonRecord = {
        ...personRecord,
        userId: Null.make(userId),
      }
      let personsIndexUpdateData = Object.empty()
      personsIndexUpdateData->Object.set(
        `all.${person}`,
        personsAllRecordToTuple(. newPersonRecord),
      )
      // update place - add userId to users dict
      let placeUpdateData = Object.empty()
      placeUpdateData->Object.set(`users.${userId}`, role)

      transaction->Transaction.update(placeDocument(firestore, place), placeUpdateData)
      transaction->Transaction.update(placeIndexDocument, personsIndexUpdateData)
      transaction->Transaction.delete(shareLinkDocument)
    })
  }
}
