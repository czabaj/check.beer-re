type classesType = {
  activeCheckbox: string,
  consumption: string,
  detailButton: string,
  inactiveUsers: string,
  list: string,
  listEmpty: string,
  root: string,
}

@module("./Place.module.css") external classes: classesType = "default"

module ActiveCheckbox = {
  @react.component
  let make = (~changes: Belt.Map.String.t<bool>, ~initialActive, ~personId, ~setChanges) => {
    let checked = changes->Belt.Map.String.getWithDefault(personId, initialActive)
    <label className={`${classes.activeCheckbox} ${Styles.utility.breakout}`}>
      {React.string("Zde")}
      <input
        checked={checked}
        type_="checkbox"
        onChange={_ => {
          let newChecked = !checked
          let newChanges =
            initialActive === newChecked
              ? changes->Belt.Map.String.remove(personId)
              : changes->Belt.Map.String.set(personId, newChecked)
          setChanges(_ => Some(newChanges))
        }}
      />
    </label>
  }
}

module ActivePersonListItem = {
  @react.component
  let make = (
    ~activeCheckbox: option<React.element>,
    ~consumptions: array<Db.userConsumption>,
    ~isCurrent,
    ~isUserAuthorized,
    ~onAddConsumption,
    ~personName,
  ) => {
    let listItemEl = React.useRef(Js.Nullable.null)
    let consumptionsStr =
      consumptions
      ->Array.map(consumption => {
        React.string(consumption.milliliters > 400 ? "X" : "I")
      })
      ->Array.joinWith("")
    let lastConsumptionsStr = React.useRef(consumptionsStr)
    let changeActive = React.useRef(false)
    changeActive.current = activeCheckbox !== None
    React.useEffect1(() => {
      switch (
        consumptionsStr === lastConsumptionsStr.current,
        changeActive.current,
        Js.Nullable.toOption(listItemEl.current),
      ) {
      | (false, false, Some(el)) =>
        lastConsumptionsStr.current = consumptionsStr
        el
        ->Webapi.Dom.Element.animate(
          {
            "backgroundColor": "var(--surface-warning)",
          },
          {
            "duration": 500,
            "iterations": 3,
            "direction": "reverse",
          },
        )
        ->ignore
      | _ => ()
      }
      None
    }, [consumptionsStr])

    <li ariaCurrent={isCurrent ? #"true" : #"false"} ref={ReactDOM.Ref.domRef(listItemEl)}>
      <div> {React.string(personName)} </div>
      {switch activeCheckbox {
      | Some(node) => node
      | None =>
        <div className={classes.consumption}>
          {isUserAuthorized(UserRoles.Staff) ||
          (isCurrent && isUserAuthorized(UserRoles.SelfService))
            ? <button
                className={Styles.utility.breakout}
                onClick={_ => onAddConsumption()}
                title="Detail konzumace"
                type_="button"
              />
            : React.null}
          {React.string(consumptionsStr)}
        </div>
      }}
    </li>
  }
}

type dialogState =
  | Hidden
  | AddConsumption({personId: string, person: Db.personsAllRecord})
  | AddPerson

type userConsumption = {milliliters: int, timestamp: float}

let pageDataRx = (auth, firestore, placeId) => {
  open Rxjs
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)->pipe(keepSome)
  let tapsWithKegsRx = placeRx->pipe2(
    distinctUntilChanged((prev: FirestoreModels.place, curr) => prev.taps == curr.taps),
    mergeMap((place: FirestoreModels.place) => {
      let tapsToKegId =
        place.taps
        ->Js.Dict.entries
        ->Array.filterMap(((tapName, maybeKegRef)) =>
          switch maybeKegRef->Null.toOption {
          | Some(kegRef) => Some((tapName, kegRef.id))
          | None => None
          }
        )
      switch tapsToKegId {
      | [] => return(Js.Dict.empty())
      | entries =>
        let kegIds = entries->Array.map(snd)
        Rxfire.collectionData(
          Firebase.query(
            Db.placeKegsCollectionConverted(firestore, placeId),
            [
              Firebase.where(Firebase.documentId(), #"in", kegIds),
              Firebase.where("depletedAt", #"==", Js.null),
            ],
          ),
        )->pipe(
          map((kegsOnTap, _) =>
            tapsToKegId
            ->Array.filterMap(
              ((tapName, kegId)) =>
                kegsOnTap
                ->Array.find(keg => Db.getUid(keg) === kegId)
                ->Option.map(keg => (tapName, keg)),
            )
            ->Js.Dict.fromArray
          ),
        )
      }
    }),
  )
  let chargedKegsWithConsumptionRx = Rxfire.collectionData(
    Firebase.query(
      Db.placeKegsCollectionConverted(firestore, placeId),
      [
        Firebase.where("depletedAt", #"==", Js.null),
        Firebase.where("recentConsumptionAt", #"!=", Js.null),
        Firebase.limit(30),
      ],
    ),
  )
  let unfinishedConsumptionsByUserRx = chargedKegsWithConsumptionRx->pipe(
    map((chargedKegsWithConsumption, _) => {
      let consumptionsByUser = Map.make()
      chargedKegsWithConsumption->Array.forEach(keg =>
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
  )->pipe(
    map(((unfinishedConsumptionsByUser, recentlyFinishedKegs), _) => {
      let recentConsumptionsByUser =
        unfinishedConsumptionsByUser
        ->Map.entries
        ->Iterator.toArrayWithMapper(((userId, consumptions)) => (userId, consumptions->Array.copy))
        ->Map.fromArray
      // TODO: show only past XY hours, filter the older out
      recentlyFinishedKegs->Array.forEach(keg =>
        Db.groupKegConsumptionsByUser(~target=recentConsumptionsByUser, keg)->ignore
      )
      // sort consumptions ty timestamp ascending
      recentConsumptionsByUser->Map.forEach(consumptions => {
        consumptions->Array.sort((a, b) => a.createdAt->DateUtils.compare(b.createdAt))
      })
      recentConsumptionsByUser
    }),
  )
  let personsAllRx = Db.PersonsIndex.allEntriesSortedRx(firestore, ~placeId)->pipe(
    map((personsAllEntries: array<(string, Db.personsAllRecord)>, _) => {
      let (active, inactive) =
        personsAllEntries->Belt.Array.partition(((_, {preferredTap})) => preferredTap !== None)
      let all = Map.fromArray(personsAllEntries)
      (all, active, inactive)
    }),
  )
  let currentUserRx = Rxfire.user(auth)->pipe(keepMap(Null.toOption))
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
  | Some(
      place,
      (allActivePersonsMap, activePersonEntries, inactivePersonEntries),
      tapsWithKegs,
      unfinishedConsumptionsByUser,
      recentConsumptionsByUser,
      currentUser,
    ) =>
    let currentUserRole = place.users->Dict.get(currentUser.uid)->Option.getExn
    let isUserAuthorized = UserRoles.isAuthorized(currentUserRole)
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
          <SectionWithHeader
            buttonsSlot={isUserAuthorized(UserRoles.Staff)
              ? <button
                  className={Styles.button.base}
                  type_="button"
                  onClick={_ => setDialog(_ => AddPerson)}>
                  {React.string("Přidat návštěvníka")}
                </button>
              : React.null}
            headerId="active_persons"
            headerSlot={React.string("Lístek")}>
            {activePersonEntries->Array.length === 0
              ? <p className=classes.listEmpty>
                  {React.string("Nikdo tu není, zkontrolujte nepřítomnost ⤵")}
                </p>
              : <ol className={`${Styles.list.base} ${classes.list}`}>
                  {activePersonEntries
                  ->Array.map(activePerson => {
                    let (personId, person) = activePerson
                    let consumptions =
                      recentConsumptionsByUser->Map.get(personId)->Option.getWithDefault([])
                    <ActivePersonListItem
                      activeCheckbox={activePersonsChanges->Option.map(changes =>
                        <ActiveCheckbox
                          changes initialActive=true personId setChanges=setActivePersonsChanges
                        />
                      )}
                      consumptions={consumptions}
                      isCurrent={person.userId->Null.mapWithDefault(false, userId =>
                        userId === currentUser.uid
                      )}
                      isUserAuthorized
                      key={personId}
                      onAddConsumption={() => {
                        setDialog(_ => AddConsumption({personId, person}))
                      }}
                      personName={person.name}
                    />
                  })
                  ->React.array}
                </ol>}
          </SectionWithHeader>
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
                className={`${Styles.button.base} ${Styles.button.variantPrimary}`}
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
                  ? <p className=classes.listEmpty> {React.string("Nikdo nechybí 👌")} </p>
                  : <ol className={`${Styles.list.base} ${classes.list}`}>
                      {inactivePersonEntries
                      ->Array.map(inactivePerson => {
                        let (personId, person) = inactivePerson
                        let recentActivityDate = person.recentActivityAt->Firebase.Timestamp.toDate
                        let isCurrent =
                          person.userId->Null.mapWithDefault(false, userId =>
                            userId === currentUser.uid
                          )
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
              let kegRef = place.taps->Js.Dict.unsafeGet(values.tap)->Null.getExn
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
            ->Option.getWithDefault([])}
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
