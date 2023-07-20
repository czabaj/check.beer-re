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

    <li ref={ReactDOM.Ref.domRef(listItemEl)}>
      <div> {React.string(personName)} </div>
      {switch activeCheckbox {
      | Some(node) => node
      | None =>
        <div className={classes.consumption}>
          <button
            className={Styles.utility.breakout}
            onClick={_ => onAddConsumption()}
            title="Detail konzumace"
            type_="button"
          />
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

let pageDataRx = (firestore, placeId) => {
  open Rxjs
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)
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
        ->Js.Dict.fromArray
      switch tapsToKegId->Js.Dict.values {
      | [] => return(Js.Dict.empty())
      | kegIds =>
        Rxfire.collectionData(
          Firebase.query(
            Db.placeKegsCollectionConverted(firestore, placeId),
            [Firebase.where(Firebase.documentId(), #"in", kegIds)],
          ),
        )->pipe(
          map((kegsOnTap, _) =>
            tapsToKegId->Js.Dict.map(
              (. kegId) => {
                kegsOnTap->Array.find(keg => Db.getUid(keg) === kegId)->Option.getExn
              },
              _,
            )
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
  combineLatest5(
    placeRx,
    personsAllRx,
    tapsWithKegsRx,
    unfinishedConsumptionsByUserRx,
    recentConsumptionsByUserRx,
  )
}

@react.component
let make = (~placeId) => {
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId="Page_Place",
    ~source=pageDataRx(firestore, placeId),
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
    ) =>
    <FormattedCurrency.Provider value={place.currency}>
      <div className={`${Styles.page.narrow} ${classes.root}`}>
        <PlaceHeader
          buttonRightSlot={<a
            {...RouterUtils.createAnchorProps("./nastaveni")}
            className={Header.classes.buttonRight}>
            <span> {React.string("⚙️")} </span>
            <span> {React.string("Nastavení")} </span>
          </a>}
          createdTimestamp={place.createdAt}
          placeName={place.name}
        />
        <main>
          <SectionWithHeader
            buttonsSlot={<button
              className={Styles.button.base}
              type_="button"
              onClick={_ => setDialog(_ => AddPerson)}>
              {React.string("Přidat návštěvníka")}
            </button>}
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
            <button
              className={Styles.button.base}
              onClick={_ => setActivePersonsChanges(_ => Some(Belt.Map.String.empty))}
              type_="button">
              {React.string("Nepřítomní")}
            </button>
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
                        <li key={personId}>
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
            onSubmit={async values => {
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
            onSubmit={async values => {
              await Db.Person.add(firestore, ~placeId, ~personName=values.name)
              hideDialog()
            }}
          />
        }}
      </div>
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
