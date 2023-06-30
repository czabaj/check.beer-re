type classesType = {
  activeCheckbox: string,
  consumption: string,
  listContainer: string,
  root: string,
}

@module("./Place.module.css") external classes: classesType = "default"

module ActiveCheckbox = {
  @react.component
  let make = (~changes: Belt.Map.String.t<bool>, ~initialActive, ~personId, ~setChanges) => {
    let checked = changes->Belt.Map.String.getWithDefault(personId, initialActive)
    <div className=classes.activeCheckbox>
      <label>
        {React.string("Aktivní")}
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
    </div>
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

// TODO: add a new person starting with "A", this sorting might be redundant
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
  let (maybeSelectedPerson, setSelectedPerson) = React.useState(_ => None)
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
            buttonsSlot={switch activePersonsChanges {
            | None =>
              <button
                className={`${Styles.buttonClasses.button}`}
                onClick={_ => setActivePersonsChanges(_ => Some(Belt.Map.String.empty))}
                type_="button">
                {React.string("Nepřítomní")}
              </button>
            | Some(changes) =>
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
                        let newPerson = {...person, preferredTap: newActive ? Some(firstTap) : None}
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
            }}
            headerSlot={React.string("Zápisník")}
            headerId="active-persons">
            <div className={classes.listContainer}>
              <ol className={`reset`}>
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
                          onClick={_ => setSelectedPerson(_ => Some(activePerson))}
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
              {switch activePersonsChanges {
              | Some(changes) =>
                <>
                  <h4>
                    <span> {React.string("Nepřítomní")} </span>
                  </h4>
                  {Belt.Map.String.size(inactivePersons) === 0
                    ? <p> {React.string("Nikdo nechybí")} </p>
                    : <ol className="reset">
                        {inactivePersons
                        ->toSortedArray
                        ->Array.map(inactivePerson => {
                          let (personId, person) = inactivePerson
                          <li key={personId}>
                            <div> {React.string(person.name)} </div>
                            <ActiveCheckbox
                              changes
                              initialActive=false
                              personId
                              setChanges=setActivePersonsChanges
                            />
                          </li>
                        })
                        ->React.array}
                      </ol>}
                </>
              | _ => React.null
              }}
            </div>
          </SectionWithHeader>
        </main>
        {switch maybeSelectedPerson {
        | None => React.null
        | Some((personId, person)) =>
          let handleDismiss = _ => setSelectedPerson(_ => None)
          <DrinkDialog
            onDismiss={handleDismiss}
            onSubmit={async values => {
              let kegRef =
                place.taps->Belt.Map.String.getExn(values.tap)->Js.Null.toOption->Option.getExn
              await Db.addConsumption(
                firestore,
                placeId,
                kegRef.id,
                {
                  createdAt: Firebase.Timestamp.now(),
                  milliliters: values.consumption,
                  person: Db.placePersonDocument(firestore, placeId, personId),
                },
              )
              await Db.updatePlacePersonsAll(
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
              handleDismiss()
            }}
            personName={person.name}
            preferredTap={person.preferredTap->Option.getExn}
            tapsWithKegs
          />
        }}
      </div>
    }
  | _ => React.null
  }
}
