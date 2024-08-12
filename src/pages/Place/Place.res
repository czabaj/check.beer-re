type classesType = {
  inactiveUsers: string,
  list: string,
  root: string,
}

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
  let personsAllRx = Db.PersonsIndex.allEntriesSortedRx(firestore, ~placeId)->op(
    map((personsAllEntries: array<(string, Db.personsAllRecord)>, _) => {
      let (active, inactive) =
        personsAllEntries->Belt.Array.partition(((_, {preferredTap})) => preferredTap !== None)
      let all = Map.fromArray(personsAllEntries)
      (all, active, inactive)
    }),
  )
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
  let (activePersonsChanges, setActivePersonsChanges) = React.useState((): option<
    Belt.Map.String.t<bool>,
  > => None)
  switch pageDataStatus.data {
  | Some(None, _, _, _, _, _) => React.string("Place not found")
  | Some(
      Some(place),
      (allActivePersonsMap, activePersonEntries, inactivePersonEntries),
      tapsWithKegs,
      unfinishedConsumptionsByUser,
      recentConsumptionsByUser,
      currentUser,
    ) =>
    let currentUserRole = place.users->Dict.get(currentUser.uid)->Option.getExn
    let isUserAuthorized = UserRoles.isAuthorized(currentUserRole, ...)
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
            activePersonsChanges
            activePersonEntries
            currentUserUid={currentUser.uid}
            isUserAuthorized
            onAddPerson={() => setDialog(_ => AddPerson)}
            onAddConsumption={((personId, person)) =>
              setDialog(_ => AddConsumption({personId, person}))}
            recentConsumptionsByUser
            setActivePersonsChanges
          />
          {switch activePersonsChanges {
          | None =>
            isUserAuthorized(UserRoles.SelfService)
              ? <button
                  className={Styles.button.base}
                  onClick={_ => setActivePersonsChanges(_ => Some(Belt.Map.String.empty))}
                  type_="button">
                  {React.string("Nepřítomní")}
                </button>
              : React.null
          | Some(changes) =>
            <>
              <button
                className={Styles.button.variantPrimary}
                onClick={_ => {
                  if changes->Belt.Map.String.size > 0 {
                    let firstTap = place.taps->Js.Dict.keys->Belt.Array.getExn(0)
                    let personsChanges =
                      changes
                      ->Belt.Map.String.mapWithKey((personId, newActive) => {
                        let person = allActivePersonsMap->Map.get(personId)->Option.getExn
                        let newPerson = {
                          ...person,
                          preferredTap: newActive ? Some(firstTap) : None,
                        }
                        newPerson
                      })
                      ->Belt.Map.String.toArray
                    Db.PersonsIndex.update(firestore, ~placeId, ~personsChanges)->ignore
                  }
                  setActivePersonsChanges(_ => None)
                }}
                type_="button">
                {React.string("Uložit")}
              </button>
              <div className={`${Styles.box.base} ${classes.inactiveUsers}`}>
                {inactivePersonEntries->Array.length === 0
                  ? <p className=SectionWithHeader.classes.emptyMessage>
                      {React.string("Nikdo nechybí 👌")}
                    </p>
                  : <ol className={`${Styles.list.base} ${classes.list}`}>
                      {inactivePersonEntries
                      ->Array.map(inactivePerson => {
                        let (personId, person) = inactivePerson
                        let recentActivityDate = person.recentActivityAt->Firebase.Timestamp.toDate
                        let isCurrent =
                          person.userId->Null.mapOr(false, userId => userId === currentUser.uid)
                        <li ariaCurrent={isCurrent ? #"true" : #"false"} key={personId}>
                          <div>
                            {React.string(`${person.name} `)}
                            <time dateTime={recentActivityDate->Js.Date.toISOString}>
                              {React.string(`byl tu `)}
                              <FormattedRelativeTime dateTime={recentActivityDate} />
                            </time>
                          </div>
                          <ActiveCheckbox
                            changes initialActive=false personId setChanges=setActivePersonsChanges
                          />
                        </li>
                      })
                      ->React.array}
                    </ol>}
              </div>
            </>
          }}
        </main>
        {switch dialogState {
        | Hidden => React.null
        | AddConsumption({personId, person}) =>
          <DrinkDialog
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
              let kegRef = place.taps->Dict.getUnsafe(values.tap)->Null.getExn
              Db.Keg.addConsumption(
                firestore,
                ~consumption={
                  milliliters: values.consumption,
                  person: Db.placePersonDocument(firestore, placeId, personId),
                },
                ~kegId=kegRef.id,
                ~personId,
                ~placeId,
              )->ignore
              hideDialog()
            }}
            personName={person.name}
            preferredTap={person.preferredTap->Option.getExn}
            tapsWithKegs
            unfinishedConsumptions={unfinishedConsumptionsByUser
            ->Map.get(personId)
            ->Option.getOr([])}
          />
        | AddPerson =>
          let existingActive = activePersonEntries->Array.map(((_, {name})) => name)
          let existingInactive = inactivePersonEntries->Array.map(((_, {name})) => name)
          <PersonAddPlace
            existingActive
            existingInactive
            onDismiss={hideDialog}
            onMoveToActive={personName => {
              let (personId, person) =
                inactivePersonEntries
                ->Array.find(((_, {name})) => name === personName)
                ->Option.getExn
              let firstTap = place.taps->Js.Dict.keys->Belt.Array.getExn(0)
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
