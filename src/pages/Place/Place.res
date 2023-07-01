type classesType = {
  activeCheckbox: string,
  consumption: string,
  inactiveUsers: string,
  list: string,
  root: string,
}

@module("./Place.module.css") external classes: classesType = "default"

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

let pageDataRx = (firestore, placeId) => {
  let placeRef = Db.placeDocumentConverted(firestore, placeId)
  let placeRx = Firebase.docDataRx(placeRef, {idField: "uid"})
  let tapsWithKegsRx = placeRx->Rxjs.pipe2(
    Rxjs.distinctUntilChanged((. prev: Db.placeConverted, curr) => prev.taps == curr.taps),
    Rxjs.mergeMap((place: Db.placeConverted) => {
      let tapsWithKeg =
        place.taps->Belt.Map.String.keep((_, maybeKegRef) => maybeKegRef !== Null.null)
      let tappedKegIds =
        tapsWithKeg
        ->Belt.Map.String.valuesToArray
        ->Belt.Array.keepMap(maybeKegReference =>
          maybeKegReference->Null.toOption->Option.map(kegRef => kegRef.id)
        )
      Firebase.collectionDataRx(
        Firebase.query(
          Db.placeKegsCollectionConverted(firestore, placeId),
          [Firebase.where(Firebase.documentId(), #"in", tappedKegIds)],
        ),
        {idField: "uid"},
      )->Rxjs.pipe(
        Rxjs.map(.(kegsOnTap, _) =>
          tapsWithKeg->Belt.Map.String.map(
            maybeRef =>
              maybeRef
              ->Null.toOption
              ->Belt.Option.flatMap(
                kegRef => kegsOnTap->Array.find(keg => Db.getUid(keg)->Option.getExn === kegRef.id),
              )
              ->Option.getExn,
          )
        ),
      )
    }),
  )
  let recentConsumptionsByUserIdRx = Db.kegsWithRecentConsumptionRx(firestore, placeId)->Rxjs.pipe(
    Rxjs.map(.(kegs, _) => {
      let consumptionsByUser = Belt.MutableMap.String.make()
      kegs->Array.forEach((keg: FirestoreModels.keg) => {
        keg.consumptions->Array.forEach(
          consumption => {
            switch Belt.MutableMap.String.get(consumptionsByUser, consumption.person.id) {
            | Some(consumptions) => consumptions->Array.push(consumption)
            | None =>
              Belt.MutableMap.String.set(consumptionsByUser, consumption.person.id, [consumption])
            }
          },
        )
      })
      consumptionsByUser
    }),
  )
  Rxjs.combineLatest3(placeRx, tapsWithKegsRx, recentConsumptionsByUserIdRx)
}

let toSortedArray = placePersons => {
  let personsAsArray = placePersons->Belt.Map.String.toArray
  personsAsArray->Array.sortInPlace(((_, a: Db.personsAllRecord), (_, b)) =>
    a.name->Js.String2.localeCompare(b.name)->Int.fromFloat
  )
  personsAsArray
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
  | Some(place, tapsWithKegs, recentConsumptionsByUserId) => {
      let (activePersons, inactivePersons) =
        place.personsAll->Belt.Map.String.partition((_, {preferredTap}) => preferredTap !== None)
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
            headerSlot={React.string("Zápisník")}
            headerId="active-persons">
            <ol className={`reset ${classes.list}`}>
              {activePersons
              ->toSortedArray
              ->Array.map(activePerson => {
                let (personId, person) = activePerson
                let consumptions =
                  recentConsumptionsByUserId->Belt.MutableMap.String.getWithDefault(personId, [])
                <li key={personId}>
                  <div> {React.string(person.name)} </div>
                  {switch activePersonsChanges {
                  | Some(changes) =>
                    <ActiveCheckbox
                      changes initialActive=true personId setChanges=setActivePersonsChanges
                    />
                  | None =>
                    <div className={classes.consumption}>
                      <button
                        className={Styles.utilityClasses.breakout}
                        onClick={_ => sendDialog(ShowAddConsumption({personId, person}))}
                        title="Otevřít kartu"
                        type_="button"
                      />
                      {consumptions
                      ->Array.map(consumption => {
                        React.string(consumption.milliliters > 400 ? "X" : "I")
                      })
                      ->React.array}
                    </div>
                  }}
                </li>
              })
              ->React.array}
            </ol>
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
                    let firstTap = place.taps->Belt.Map.String.keysToArray->Belt.Array.getExn(0)
                    Db.updatePlacePersonsAll(
                      firestore,
                      placeId,
                      changes
                      ->Belt.Map.String.mapWithKey((personId, newActive) => {
                        let person = place.personsAll->Belt.Map.String.getExn(personId)
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
                {Belt.Map.String.size(inactivePersons) === 0
                  ? <p> {React.string("Nikdo nechybí 👌")} </p>
                  : <ol className={`reset ${classes.list}`}>
                      {inactivePersons
                      ->toSortedArray
                      ->Array.map(inactivePerson => {
                        let (personId, person) = inactivePerson
                        <li key={personId}>
                          <div> {React.string(person.name)} </div>
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
            onDismiss={hideDialog}
            onSubmit={async values => {
              let kegRef =
                place.taps->Belt.Map.String.getExn(values.tap)->Js.Null.toOption->Option.getExn
              let addConsumptionPromise = Db.addConsumption(
                firestore,
                placeId,
                kegRef.id,
                {
                  createdAt: Firebase.Timestamp.now(),
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
          let existingActive =
            activePersons->Belt.Map.String.map(({name}) => name)->Belt.Map.String.valuesToArray
          let existingInactive =
            inactivePersons->Belt.Map.String.map(({name}) => name)->Belt.Map.String.valuesToArray
          <PersonAddNew
            existingActive
            existingInactive
            onDismiss={hideDialog}
            onMoveToActive={personName => {
              let (personId, person) =
                inactivePersons
                ->Belt.Map.String.findFirstBy((_, {name}) => name === personName)
                ->Option.getExn
              let firstTap = place.taps->Belt.Map.String.keysToArray->Belt.Array.getExn(0)
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
    }
  | _ => React.null
  }
}
