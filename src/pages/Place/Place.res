type classesType = {descriptionList: string, root: string}

@module("./Place.module.css") external classes: classesType = "default"

type activePersonInfo = {
  consumptions: array<FirestoreModels.consumption>,
  id: string,
  name: string,
  preferredTap: string,
}

let getActivePersons = (place: Db.placeConverted, kegs: array<FirestoreModels.keg>) => {
  let activePersons = place.personsAll->Belt.Map.String.reduce(Belt.MutableMap.String.make(), (
    activePersons,
    id,
    (name, _, maybePreferredTap),
  ) => {
    switch maybePreferredTap {
    | Some(preferredTap) => {
        activePersons->Belt.MutableMap.String.set(id, {consumptions: [], id, name, preferredTap})
        activePersons
      }
    | None => activePersons
    }
  })
  kegs->Array.forEach(({consumptions}) => {
    consumptions->Array.forEach(consumption => {
      switch Belt.MutableMap.String.get(activePersons, consumption.person.id) {
      | Some(activePersonRecord) => activePersonRecord.consumptions->Array.push(consumption)
      | _ => ()
      }
    })
  })
  activePersons
  ->Belt.MutableMap.String.valuesToArray
  ->Js.Array2.sortInPlaceWith((a, b) => Js.String2.localeCompare(a.name, b.name)->Int.fromFloat)
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
  let kegsWithRecentConsumption = Db.kegsWithRecentConsumptionRx(firestore, placeId)
  Rxjs.combineLatest3(placeRx, tapsWithKegsRx, kegsWithRecentConsumption)
}

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let placePageStatus = Firebase.useObservable(
    ~observableId="PlacePage",
    ~source=pageDataRx(firestore, placeId),
  )
  let (maybeSelectedPerson, setSelectedPerson) = React.useState(_ => None)
  switch placePageStatus.data {
  | Some(place, tapsWithKegs, kegsWithRecentConsumption) => {
      let activePersons = getActivePersons(place, kegsWithRecentConsumption)
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
            buttonsSlot={<button className={Styles.buttonClasses.button} type_="button">
              {React.string("Obsazení")}
            </button>}
            headerSlot={React.string("U stolu")}
            headerId="active-persons">
            <dl className={classes.descriptionList}>
              {activePersons
              ->Array.map(person => {
                <div key={person.id}>
                  <dt>
                    {React.string(person.name)}
                    <button
                      className={Styles.utilityClasses.breakout}
                      onClick={_ => setSelectedPerson(_ => Some(person))}
                      title="Otevřít kartu"
                      type_="button"
                    />
                  </dt>
                  <dd> {React.string("XII")} </dd>
                </div>
              })
              ->React.array}
            </dl>
          </SectionWithHeader>
        </main>
        {switch maybeSelectedPerson {
        | None => React.null
        | Some(selectedPerson) =>
          <DrinkDialog
            onDismiss={_ => setSelectedPerson(_ => None)}
            personName={selectedPerson.name}
            preferredTap={selectedPerson.preferredTap}
            tapsWithKegs
          />
        }}
      </div>
    }
  | _ => React.null
  }
}
