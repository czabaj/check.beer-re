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

type dialogEvent =
  | Hide
  | ShowAddConsumption({personId: string, person: Db.personsAllRecord})
  | ShowAddPerson

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddConsumption({personId, person}) => AddConsumption({personId, person})
  | ShowAddPerson => AddPerson
  }
}

type userConsumption = {milliliters: int, timestamp: float}

let pageDataRx = (firestore, placeId) => {
  let placeRef = Db.placeDocumentConverted(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)
  let tapsWithKegsRx = placeRx->Rxjs.pipe2(
    Rxjs.distinctUntilChanged((prev: Db.placeConverted, curr) => prev.taps == curr.taps),
    Rxjs.mergeMap((place: Db.placeConverted) => {
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
      | [] => Rxjs.return(Js.Dict.empty())
      | kegIds =>
        Rxfire.collectionData(
          Firebase.query(
            Db.placeKegsCollectionConverted(firestore, placeId),
            [Firebase.where(Firebase.documentId(), #"in", kegIds)],
          ),
        )->Rxjs.pipe(
          Rxjs.map((kegsOnTap, _) =>
            tapsToKegId->Js.Dict.map(
              (. kegId) => {
                kegsOnTap->Array.find(keg => Db.getUid(keg)->Option.getExn === kegId)->Option.getExn
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
      ],
    ),
  )
  let unfinishedConsumptionsByUserRx = chargedKegsWithConsumptionRx->Rxjs.pipe(
    Rxjs.map((chargedKegsWithConsumption, _) => {
      let consumptionsByUser = Belt.MutableMap.String.make()
      chargedKegsWithConsumption->Array.forEach(keg =>
        Db.groupKegConsumptionsByUser(~target=consumptionsByUser, keg)->ignore
      )
      consumptionsByUser->Belt.MutableMap.String.forEach((_, consumptions) => {
        consumptions->Array.sort((a, b) => a.createdAt->DateUtils.compare(b.createdAt))
      })
      consumptionsByUser
    }),
  )
  let recentlyFinishedKegsRx = Db.recentlyFinishedKegsRx(firestore, placeId)
  let recentConsumptionsByUserRx = Rxjs.combineLatest2((
    unfinishedConsumptionsByUserRx,
    recentlyFinishedKegsRx,
  ))->Rxjs.pipe(
    Rxjs.map(((unfinishedConsumptionsByUser, recentlyFinishedKegs), _) => {
      let recentConsumptionsByUser =
        unfinishedConsumptionsByUser
        ->Belt.MutableMap.String.toArray
        ->Array.map(((userId, consumptions)) => (userId, consumptions->Array.copy))
        ->Belt.MutableMap.String.fromArray
      // TODO: show only past XY hours, filter the older out
      recentlyFinishedKegs->Array.forEach(keg =>
        Db.groupKegConsumptionsByUser(~target=recentConsumptionsByUser, keg)->ignore
      )
      // sort consumptions ty timestamp ascending
      recentConsumptionsByUser->Belt.MutableMap.String.forEach((_, consumptions) => {
        consumptions->Array.sort((a, b) => a.createdAt->DateUtils.compare(b.createdAt))
      })
      recentConsumptionsByUser
    }),
  )
  let personsSorted = placeRx->Rxjs.pipe(
    Rxjs.map((place: Db.placeConverted, _) => {
      let personsAllEntries = place.personsAll->Js.Dict.entries
      personsAllEntries->Array.sort(((_, a), (_, b)) => {
        a.name->Js.String2.localeCompare(b.name)
      })
      personsAllEntries->Belt.Array.partition(((_, {preferredTap})) => preferredTap !== None)
    }),
  )
  Rxjs.combineLatest5((
    placeRx,
    personsSorted,
    tapsWithKegsRx,
    unfinishedConsumptionsByUserRx,
    recentConsumptionsByUserRx,
  ))
}

@react.component
let make = (~placeId) => {
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId="Page_Place",
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  let (activePersonsChanges, setActivePersonsChanges) = React.useState((): option<
    Belt.Map.String.t<bool>,
  > => None)
  switch pageDataStatus.data {
  | Some(
      place,
      (activePersonEntries, inactivePersonEntries),
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
              className={Styles.button.button}
              type_="button"
              onClick={_ => sendDialog(ShowAddPerson)}>
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
                      recentConsumptionsByUser->Belt.MutableMap.String.getWithDefault(personId, [])
                    <ActivePersonListItem
                      activeCheckbox={activePersonsChanges->Option.map(changes =>
                        <ActiveCheckbox
                          changes initialActive=true personId setChanges=setActivePersonsChanges
                        />
                      )}
                      consumptions={consumptions}
                      key={personId}
                      onAddConsumption={() => {
                        sendDialog(ShowAddConsumption({personId, person}))
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
              className={Styles.button.button}
              onClick={_ => setActivePersonsChanges(_ => Some(Belt.Map.String.empty))}
              type_="button">
              {React.string("Nepřítomní")}
            </button>
          | Some(changes) =>
            <>
              <button
                className={`${Styles.button.button} ${Styles.button.variantPrimary}`}
                onClick={_ => {
                  if changes->Belt.Map.String.size > 0 {
                    let firstTap = place.taps->Js.Dict.keys->Belt.Array.getExn(0)
                    Db.updatePlacePersonsAll(
                      firestore,
                      placeId,
                      changes
                      ->Belt.Map.String.mapWithKey((personId, newActive) => {
                        let person = place.personsAll->Js.Dict.unsafeGet(personId)
                        let newPerson = {
                          ...person,
                          preferredTap: newActive ? Some(firstTap) : None,
                        }
                        newPerson
                      })
                      ->Belt.Map.String.toArray,
                    )->ignore
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
              Db.deleteConsumption(
                firestore,
                placeId,
                consumption.kegId,
                consumption.consumptionId,
              )->ignore
            }}
            onDismiss={hideDialog}
            onSubmit={async values => {
              let kegRef =
                place.taps->Js.Dict.unsafeGet(values.tap)->Js.Null.toOption->Option.getExn
              let addConsumptionPromise = Db.addConsumption(
                firestore,
                placeId,
                kegRef.id,
                {
                  milliliters: values.consumption,
                  person: Db.placePersonDocument(firestore, placeId, personId),
                },
              )
              let updatePlacePersonPromise = Db.updatePlacePersonsAll(
                firestore,
                placeId,
                [
                  (
                    personId,
                    {
                      ...person,
                      preferredTap: Some(values.tap),
                      recentActivityAt: Firebase.Timestamp.now(),
                    },
                  ),
                ],
              )
              try {
                let _ = await Js.Promise2.all([addConsumptionPromise, updatePlacePersonPromise])
                hideDialog()
              } catch {
              | e => Js.log2("Error while adding consumption", e)
              }
            }}
            personName={person.name}
            preferredTap={person.preferredTap->Option.getExn}
            tapsWithKegs
            unfinishedConsumptions={unfinishedConsumptionsByUser->Belt.MutableMap.String.getWithDefault(
              personId,
              [],
            )}
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
              Db.updatePlacePersonsAll(
                firestore,
                placeId,
                [(personId, {...person, preferredTap: Some(firstTap)})],
              )->ignore
              hideDialog()
            }}
            onSubmit={async values => {
              await Db.addPerson(firestore, placeId, values.name)
              hideDialog()
            }}
          />
        }}
      </div>
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
