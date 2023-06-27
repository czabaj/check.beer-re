type classesType = {root: string}

@module("./Place.module.css") external classes: classesType = "default"

type activePersonInfo = {
  consumptions: array<FirestoreModels.consumption>,
  id: string,
  name: string,
  preferredTap: string,
}

let getActivePersons = (place: FirestoreModels.place, kegs: array<FirestoreModels.keg>) => {
  let activePersons =
    place.personsAll
    ->Js.Dict.entries
    ->Array.reduce(Js.Dict.empty(), (activePersons, (id, (name, _, maybePreferredTap))) => {
      switch maybePreferredTap {
      | Some(preferredTap) => {
          activePersons->Js.Dict.set(id, {consumptions: [], id, name, preferredTap})
          activePersons
        }
      | None => activePersons
      }
    })
  kegs->Array.forEach(({consumptions}) => {
    consumptions->Array.forEach(consumption => {
      let maybeActivePersonRecord = Js.Dict.get(activePersons, consumption.person.id)
      switch maybeActivePersonRecord {
      | Some(activePersonRecord) => activePersonRecord.consumptions->Array.push(consumption)
      | _ => ()
      }
    })
  })
  activePersons
  ->Js.Dict.values
  ->Js.Array2.sortInPlaceWith((a, b) => Js.String2.localeCompare(a.name, b.name)->Int.fromFloat)
}

@react.component
let make = (~placeId) => {
  let placeDoc = Db.usePlaceDocData(placeId)
  let kegsWithRecentConsumptionCollection = Db.useKegsWithRecentConsumptionCollection(placeId)
  let (maybeSelectedPerson, setSelectedPerson) = React.useState(_ => None)
  switch (placeDoc.data, kegsWithRecentConsumptionCollection.data) {
  | (Some(place), Some(kegs)) => {
      let activePersons = getActivePersons(place, kegs)
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
          <dl>
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
                <dd> {React.string("XY")} </dd>
              </div>
            })
            ->React.array}
          </dl>
        </main>
        {switch maybeSelectedPerson {
        | None => React.null
        | Some(selectedPerson) =>
          <PersonDialog
            personName={selectedPerson.name}
            onDismiss={_ => setSelectedPerson(_ => None)}
            usedTap={selectedPerson.preferredTap}
          />
        }}
      </div>
    }
  | _ => React.null
  }
}
