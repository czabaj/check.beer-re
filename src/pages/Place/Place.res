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
    <label className={`${classes.activeCheckbox} ${Styles.utilityClasses.breakout}`}>
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

module DetailButton = {
  @react.component
  let make = (~onClick) => {
    <ButtonDetail className={classes.detailButton} onClick={onClick} title="Osobní karta" />
  }
}

module ActivePersonListItem = {
  @react.component
  let make = (
    ~activeCheckbox: option<React.element>,
    ~consumptions: array<Db.userConsumption>,
    ~onAddConsumption,
    ~onShowDetail,
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
            className={Styles.utilityClasses.breakout}
            onClick={_ => onAddConsumption()}
            title="Otevřít kartu"
            type_="button"
          />
          {React.string(consumptionsStr)}
        </div>
      }}
      <DetailButton onClick={_ => onShowDetail()} />
    </li>
  }
}

type dialogState =
  | Hidden
  | AddConsumption({personId: string, person: Db.personsAllRecord})
  | AddPerson
  | PersonDetail({personId: string, person: Db.personsAllRecord})

type dialogEvent =
  | Hide
  | ShowAddConsumption({personId: string, person: Db.personsAllRecord})
  | ShowAddPerson
  | ShowPersonDetail({personId: string, person: Db.personsAllRecord})

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddConsumption({personId, person}) => AddConsumption({personId, person})
  | ShowAddPerson => AddPerson
  | ShowPersonDetail({personId, person}) => PersonDetail({personId, person})
  }
}

type userConsumption = {milliliters: int, timestamp: float}

let pageDataRx = (firestore, placeId) => {
  let placeRef = Db.placeDocumentConverted(firestore, placeId)
  let placeRx = Firebase.docDataRx(placeRef, {idField: "uid"})
  let tapsWithKegsRx = placeRx->Rxjs.pipe2(
    Rxjs.distinctUntilChanged((. prev: Db.placeConverted, curr) => prev.taps == curr.taps),
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
      Firebase.collectionDataRx(
        Firebase.query(
          Db.placeKegsCollectionConverted(firestore, placeId),
          [Firebase.where(Firebase.documentId(), #"in", tapsToKegId->Js.Dict.values)],
        ),
        Db.reactFireOptions,
      )->Rxjs.pipe(
        Rxjs.map(.(kegsOnTap, _) =>
          tapsToKegId->Js.Dict.map(
            (. kegId) => {
              kegsOnTap->Array.find(keg => Db.getUid(keg)->Option.getExn === kegId)->Option.getExn
            },
            _,
          )
        ),
      )
    }),
  )
  let kegsWithRecentConsumptionRx = Db.kegsWithRecentConsumptionRx(firestore, placeId)
  let recentConsumptionsByUserIdRx = kegsWithRecentConsumptionRx->Rxjs.pipe(
    Rxjs.map(.(kegs, _) => {
      let consumptionsByUser = Belt.MutableMap.String.make()
      // TODO: show only past XY hours, filter the older out
      kegs->Array.forEach(keg =>
        Db.groupKegConsumptionsByUser(~target=consumptionsByUser, keg)->ignore
      )
      // sort consumptions ty timestamp ascending
      consumptionsByUser->Belt.MutableMap.String.forEach((_, consumptions) => {
        consumptions->Array.sortInPlace((a, b) => (a.timestamp -. b.timestamp)->Int.fromFloat)
      })
      consumptionsByUser
    }),
  )
  let personsSorted = placeRx->Rxjs.pipe(
    Rxjs.map(.(place: Db.placeConverted, _) => {
      let personsAllEntries = place.personsAll->Js.Dict.entries
      personsAllEntries->Array.sortInPlace(((_, a), (_, b)) => {
        a.name->Js.String2.localeCompare(b.name)->Int.fromFloat
      })
      personsAllEntries->Belt.Array.partition(((_, {preferredTap})) => preferredTap !== None)
    }),
  )
  Rxjs.combineLatest5((
    placeRx,
    personsSorted,
    tapsWithKegsRx,
    kegsWithRecentConsumptionRx,
    recentConsumptionsByUserIdRx,
  ))
}

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let placePageStatus = Firebase.useObservable(
    ~observableId="PlacePage",
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  let (activePersonsChanges, setActivePersonsChanges) = React.useState((): option<
    Belt.Map.String.t<bool>,
  > => None)
  switch placePageStatus.data {
  | Some(
      place,
      (activePersonEntries, inactivePersonEntries),
      tapsWithKegs,
      kegsWithRecentConsumption,
      recentConsumptionsByUserId,
    ) =>
    <FormattedCurrency.Provider value={place.currency}>
      <div className={classes.root}>
        <PlaceHeader
          placeName={place.name}
          createdTimestamp={place.createdAt}
          slotRightButton={<a
            {...RouterUtils.createAnchorProps("./nastaveni")}
            className={PlaceHeader.classes.iconButton}>
            <span> {React.string("⚙️")} </span>
            <span> {React.string("Nastavení")} </span>
          </a>}
        />
        <main>
          <SectionWithHeader
            buttonsSlot={<button
              className={Styles.buttonClasses.button}
              type_="button"
              onClick={_ => sendDialog(ShowAddPerson)}>
              {React.string("Přidat osobu")}
            </button>}
            headerId="active_persons"
            headerSlot={React.string("Lístek")}>
            {activePersonEntries->Array.length === 0
              ? <p className=classes.listEmpty>
                  {React.string("Nikdo tu není, zkontrolujte nepřítomnost ⤵")}
                </p>
              : <ol className={`reset ${classes.list}`}>
                  {activePersonEntries
                  ->Array.map(activePerson => {
                    let (personId, person) = activePerson
                    let consumptions =
                      recentConsumptionsByUserId->Belt.MutableMap.String.getWithDefault(
                        personId,
                        [],
                      )
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
                      onShowDetail={() => {
                        sendDialog(ShowPersonDetail({person, personId}))
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
              className={Styles.buttonClasses.button}
              onClick={_ => setActivePersonsChanges(_ => Some(Belt.Map.String.empty))}
              type_="button">
              {React.string("Nepřítomní")}
            </button>
          | Some(changes) =>
            <>
              <button
                className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
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
              <div className={`${Styles.boxClasses.base} ${classes.inactiveUsers}`}>
                {inactivePersonEntries->Array.length === 0
                  ? <p className=classes.listEmpty> {React.string("Nikdo nechybí 👌")} </p>
                  : <ol className={`reset ${classes.list}`}>
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
                          <DetailButton
                            onClick={_ => sendDialog(ShowPersonDetail({person, personId}))}
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
          />
        | AddPerson =>
          let existingActive = activePersonEntries->Array.map(((_, {name})) => name)
          let existingInactive = inactivePersonEntries->Array.map(((_, {name})) => name)
          <PersonAddNew
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
        | PersonDetail({person, personId}) => {
            let unfinishedConsumptions =
              kegsWithRecentConsumption
              ->Belt.Array.keep(keg => keg.depletedAt === Null.null)
              ->Belt.Array.flatMap(keg =>
                keg.consumptions
                ->Belt.Map.String.toArray
                ->Belt.Array.keepMap(((timestampStr, consumption)): option<
                  PersonDetail.unfinishedConsumptionsRecord,
                > => {
                  switch consumption.person.id === personId {
                  | false => None
                  | true =>
                    Some({
                      beer: keg.beer,
                      consumptionId: timestampStr,
                      createdAt: timestampStr->Float.fromString->Option.getExn->Js.Date.fromFloat,
                      kegId: Db.getUid(keg)->Option.getExn,
                      milliliters: consumption.milliliters,
                    })
                  }
                })
              )
            unfinishedConsumptions->Array.sortInPlace((a, b) =>
              (b.createdAt->Js.Date.getTime -. a.createdAt->Js.Date.getTime)->Int.fromFloat
            )
            let currentIdx = activePersonEntries->Array.findIndex(((id, _)) => id === personId)
            let hasNext = currentIdx !== -1 && currentIdx < Array.length(activePersonEntries) - 1
            let hasPrevious = currentIdx > 0
            let handleCycle = increase => {
              let allowed = increase ? hasNext : hasPrevious
              if allowed {
                let nextIdx = currentIdx + (increase ? 1 : -1)
                let (nextPersonId, nextPerson) = activePersonEntries->Belt.Array.getExn(nextIdx)
                sendDialog(
                  ShowPersonDetail({
                    person: nextPerson,
                    personId: nextPersonId,
                  }),
                )
              }
            }
            <PersonDetail
              hasNext
              hasPrevious
              onDeleteConsumption={consumption => {
                Db.deleteConsumption(
                  firestore,
                  placeId,
                  consumption.kegId,
                  consumption.consumptionId,
                )->ignore
              }}
              onDeletePerson={_ => {
                Db.deletePerson(firestore, placeId, personId)->ignore
              }}
              onDismiss={hideDialog}
              onNextPerson={_ => handleCycle(true)}
              onPreviousPerson={_ => handleCycle(false)}
              person
              personId
              placeId
              unfinishedConsumptions
            />
          }
        }}
      </div>
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
