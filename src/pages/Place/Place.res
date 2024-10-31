type classesType = {root: string}

@module("./Place.module.css") external classes: classesType = "default"

type dialogState =
  | Hidden
  | AddConsumption({personId: string, person: Db.personsAllRecord})
  | AddPerson

type userConsumption = {milliliters: int, timestamp: float}

let pageDataRx = (auth, firestore, placeId) => {
  open Rxjs
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)
  let chargedKegsRx = Db.allChargedKegsRx(firestore, placeId)
  let placeTapsRx =
    placeRx
    ->op(
      distinctUntilChanged((prev, curr) =>
        switch ((prev: option<FirestoreModels.place>), curr) {
        | (Some(prevPlace), Some(currPlace)) => prevPlace.taps == currPlace.taps
        | _ => false
        }
      ),
    )
    ->op(
      map((maybePlace: option<FirestoreModels.place>, _) =>
        maybePlace->Option.map(place => place.taps)
      ),
    )
  let tapsWithKegsRx = combineLatest2(placeTapsRx, chargedKegsRx)->op(
    map((data, _) => {
      switch data {
      | (Some(placeTaps), chargedKegs) =>
        placeTaps
        ->Dict.toArray
        ->Array.filterMap(((tap, maybeKegRef)) =>
          maybeKegRef
          ->Null.toOption
          ->Option.flatMap(
            (kegRef: Firebase.documentReference<FirestoreModels.keg>) =>
              chargedKegs->Array.find(keg => Db.getUid(keg) === kegRef.id),
          )
          ->Option.map(keg => (tap, keg))
        )
        ->Dict.fromArray
      | _ => Js.Dict.empty()
      }
    }),
  )
  let unfinishedConsumptionsByUserRx = chargedKegsRx->op(
    map((chargedKegs, _) => {
      let consumptionsByUser = Map.make()
      chargedKegs->Array.forEach(keg =>
        Db.groupKegConsumptionsByUser(~target=consumptionsByUser, keg)->ignore
      )
      consumptionsByUser->Map.forEach(consumptions => {
        consumptions->Array.sort((a, b) => a.createdAt->DateUtils.compare(b.createdAt))
      })
      consumptionsByUser
    }),
  )
  let recentlyFinishedKegsRx = Db.recentlyFinishedKegsRx(firestore, placeId)
  let recentConsumptionsByUserRx = combineLatest2(
    unfinishedConsumptionsByUserRx,
    recentlyFinishedKegsRx,
  )->op(
    map(((unfinishedConsumptionsByUser, recentlyFinishedKegs), _) => {
      let recentConsumptionsByUser = ObjectUtils.structuredClone(unfinishedConsumptionsByUser)
      recentlyFinishedKegs->Array.forEach(keg =>
        Db.groupKegConsumptionsByUser(~target=recentConsumptionsByUser, keg)->ignore
      )
      let twelweHoursAgo = Date.now() -. Db.slidingWindowInMillis
      recentConsumptionsByUser
      ->Map.entries
      ->Iterator.toArrayWithMapper(((userId, consumptions)) => {
        let consumptionsInSlidingWindow =
          consumptions->Array.filter(
            consumption => consumption.createdAt->Date.getTime > twelweHoursAgo,
          )
        // sort consumptions ty timestamp ascending
        consumptionsInSlidingWindow->Array.sort(
          (a, b) => a.createdAt->DateUtils.compare(b.createdAt),
        )
        (userId, consumptionsInSlidingWindow)
      })
      ->Map.fromArray
    }),
  )
  let personsAllRx = Db.PersonsIndex.allEntriesSortedRx(firestore, ~placeId)
  let currentUserRx = Rxfire.user(auth)->op(keepMap(Null.toOption))
  combineLatest6(
    placeRx,
    personsAllRx,
    tapsWithKegsRx,
    unfinishedConsumptionsByUserRx,
    recentConsumptionsByUserRx,
    currentUserRx,
  )
}

@react.component
let make = (~placeId) => {
  let auth = Reactfire.useAuth()
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId=`Page_Place_${placeId}`,
    ~source=pageDataRx(auth, firestore, placeId),
  )
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  switch pageDataStatus.data {
  | Some(None, _, _, _, _, _) => React.string("Place not found")
  | Some(
      Some(place),
      personEntries,
      tapsWithKegs,
      unfinishedConsumptionsByUser,
      recentConsumptionsByUser,
      currentUser,
    ) =>
    let (currentUserRole, _) = place.accounts->Dict.get(currentUser.uid)->Option.getExn
    let isUserAuthorized = UserRoles.isAuthorized(currentUserRole, ...)
    let formatConsumption = BackendUtils.getFormatConsumption(place.consumptionSymbols)
    let dispatchFreeTableNotification = NotificationEvents.useDispatchFreeTableNotification()
    let dispatchFreshKegNotification = NotificationEvents.useDispatchFreshKegNotification()

    <FormattedCurrency.Provider value={place.currency}>
      <div className={`${Styles.page.narrow} ${classes.root}`}>
        <PlaceHeader
          buttonRightSlot={isUserAuthorized(UserRoles.Staff)
            ? <a
                {...RouterUtils.createAnchorProps("./nastaveni")}
                className={Header.classes.buttonRight}>
                <span> {React.string("⚙️")} </span>
                <span> {React.string("Nastavení")} </span>
              </a>
            : React.null}
          createdTimestamp={place.createdAt}
          placeName={place.name}
        />
        <main>
          <BeerList
            currentUserUid={currentUser.uid}
            formatConsumption
            isUserAuthorized
            onAddPerson={() => setDialog(_ => AddPerson)}
            onAddConsumption={((personId, person)) =>
              setDialog(_ => AddConsumption({personId, person}))}
            onTogglePersonVisibility={((personId, person): (string, Db.personsAllRecord)) => {
              let preferredTap =
                person.preferredTap->Option.isSome ? None : place.taps->Js.Dict.keys->Array.get(0)
              Db.PersonsIndex.update(
                firestore,
                ~placeId,
                ~personsChanges=[(personId, {...person, preferredTap})],
              )->ignore
            }}
            personEntries
            recentConsumptionsByUser
          />
        </main>
        {switch dialogState {
        | Hidden => React.null
        | AddConsumption({personId, person}) =>
          <DrinkDialog
            formatConsumption
            onDeleteConsumption={consumption => {
              Db.Keg.deleteConsumption(
                firestore,
                ~placeId,
                ~kegId=consumption.kegId,
                ~consumptionId=consumption.consumptionId,
              )->ignore
            }}
            onDismiss={hideDialog}
            onSubmit={values => {
              let keg = tapsWithKegs->Dict.getUnsafe(values.tap)
              let kegRef = Db.kegDoc(firestore, placeId, Db.getUid(keg))
              let firstBeerFromKeg = keg.consumptions->Dict.keysToArray->Array.length === 0
              if firstBeerFromKeg {
                dispatchFreshKegNotification(kegRef)
                ->Promise.then(_ => Promise.resolve())
                ->Promise.catch(error => {
                  let exn = Js.Exn.asJsExn(error)->Option.getExn
                  LogUtils.captureException(exn)
                  Promise.resolve()
                })
                ->ignore
              } else {
                let freeTable =
                  recentConsumptionsByUser
                  ->Map.values
                  ->Array.fromIterator
                  ->Array.every(consumptions => consumptions->Array.length === 0)
                if freeTable {
                  dispatchFreeTableNotification(Db.placeDocument(firestore, placeId))
                  ->Promise.then(_ => Promise.resolve())
                  ->Promise.catch(error => {
                    let exn = Js.Exn.asJsExn(error)->Option.getExn
                    LogUtils.captureException(exn)
                    Promise.resolve()
                  })
                  ->ignore
                }
              }

              Db.Keg.addConsumption(
                firestore,
                ~consumption={
                  milliliters: values.consumption,
                  person: Db.placePersonDocument(firestore, placeId, personId),
                },
                ~kegId=kegRef.id,
                ~personId,
                ~placeId,
                ~tapName=values.tap,
              )->ignore
              hideDialog()
            }}
            personName={person.name}
            preferredTap={switch person.preferredTap {
            | Some(tap) => tap
            | None => place.taps->Js.Dict.keys->Array.getUnsafe(0)
            }}
            tapsWithKegs
            unfinishedConsumptions={unfinishedConsumptionsByUser
            ->Map.get(personId)
            ->Option.getOr([])}
          />
        | AddPerson =>
          let (active, inactive) =
            personEntries->Belt.Array.partition(((_, {preferredTap})) => preferredTap !== None)
          let existingActive = active->Array.map(((_, {name})) => name)
          let existingInactive = inactive->Array.map(((_, {name})) => name)
          <PersonAddPlace
            existingActive
            existingInactive
            onDismiss={hideDialog}
            onMoveToActive={personName => {
              let (personId, person) =
                inactive
                ->Array.find(((_, {name})) => name === personName)
                ->Option.getExn
              let firstTap = place.taps->Js.Dict.keys->Array.getUnsafe(0)
              Db.PersonsIndex.update(
                firestore,
                ~placeId,
                ~personsChanges=[(personId, {...person, preferredTap: Some(firstTap)})],
              )->ignore
              hideDialog()
            }}
            onSubmit={values => {
              Db.Person.add(firestore, ~placeId, ~personName=values.name)->ignore
              hideDialog()
            }}
          />
        }}
      </div>
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
