type classesType = {root: string, table: string}

@module("./PlacePersonsSetting.module.css") external classes: classesType = "default"

type dialogState =
  | Hidden
  | AddPerson
  | PersonDetail({personId: string, person: Db.personsAllRecord})

type dialogEvent =
  | Hide
  | ShowAddPerson
  | ShowPersonDetail({personId: string, person: Db.personsAllRecord})

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddPerson => AddPerson
  | ShowPersonDetail({personId, person}) => PersonDetail({personId, person})
  }
}

let pageDataRx = (firestore, placeId) => {
  let placeRef = Db.placeDocumentConverted(firestore, placeId)
  let placeRx = Firebase.docDataRx(placeRef, Db.reactFireOptions)
  let unfinishedConsumptionsByUserRx = Db.unfinishedConsumptionsByUserRx(firestore, placeId)
  Rxjs.combineLatest2((placeRx, unfinishedConsumptionsByUserRx))
}

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let pageDataStatus = Firebase.useObservable(
    ~observableId="Page_PlacePersonsSetting",
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  switch pageDataStatus.data {
  | Some((place, unfinishedConsumptionsByUser)) => {
      let personsEntries = place.personsAll->Js.Dict.entries
      personsEntries->Array.sortInPlace(((_, a), (_, b)) => {
        a.name->Js.String2.localeCompare(b.name)->Int.fromFloat
      })
      <FormattedCurrency.Provider value={place.currency}>
        <div className=classes.root>
          <PlaceHeader
            placeName={place.name} createdTimestamp={place.createdAt} slotRightButton={React.null}
          />
          <main>
            <SectionWithHeader
              buttonsSlot={<button
                className={Styles.buttonClasses.button}
                type_="button"
                onClick={_ => sendDialog(ShowAddPerson)}>
                {React.string("Přidat osobu")}
              </button>}
              headerId="persons_accounts"
              headerSlot={React.string("Účetnictví osob")}>
              <table
                ariaLabelledby="persons_accounts"
                className={`${Styles.tableClasses.stretch} ${classes.table}`}>
                <thead>
                  <tr>
                    <th scope="col"> {React.string("Osoba")} </th>
                    <th scope="col"> {React.string("Poslední aktivita")} </th>
                    <th scope="col"> {React.string("Bilance")} </th>
                  </tr>
                </thead>
                <tbody>
                  {personsEntries
                  ->Array.map(((personId, person)) => {
                    <tr key=personId>
                      <th scope="row">
                        {React.string(person.name)}
                        <button
                          className={Styles.utilityClasses.breakout}
                          onClick={_ => sendDialog(ShowPersonDetail({personId, person}))}
                          title="Detail konzumace"
                          type_="button"
                        />
                      </th>
                      <td>
                        <FormattedRelativeTime
                          dateTime={person.recentActivityAt->Firebase.Timestamp.toDate}
                        />
                      </td>
                      <td>
                        <FormattedCurrency
                          format={FormattedCurrency.formatAccounting} value=person.balance
                        />
                      </td>
                    </tr>
                  })
                  ->React.array}
                </tbody>
              </table>
            </SectionWithHeader>
          </main>
          {switch dialogState {
          | Hidden => React.null
          | PersonDetail({personId, person}) =>
            let currentIdx = personsEntries->Array.findIndex(((id, _)) => id === personId)
            if currentIdx === -1 {
              // Possibly, the person was deleted on the backend best to close the dialog
              hideDialog()
              React.null
            } else {
              let hasNext = currentIdx < Array.length(personsEntries) - 1
              let hasPrevious = currentIdx > 0
              let handleCycle = increase => {
                let allowed = increase ? hasNext : hasPrevious
                if allowed {
                  let nextIdx = currentIdx + (increase ? 1 : -1)
                  let (nextPersonId, nextPerson) = personsEntries->Belt.Array.getExn(nextIdx)
                  sendDialog(
                    ShowPersonDetail({
                      person: nextPerson,
                      personId: nextPersonId,
                    }),
                  )
                }
              }
              let unfinishedConsumptions =
                unfinishedConsumptionsByUser->Belt.MutableMap.String.getWithDefault(personId, [])
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
                unfinishedConsumptions={unfinishedConsumptions}
              />
            }
          | AddPerson =>
            <PersonAddPersonsSetting
              existingNames={place.personsAll->Js.Dict.values->Array.map(p => p.name)}
              onDismiss={hideDialog}
              onSubmit={async values => {
                await Db.addPerson(firestore, placeId, values.name)
                hideDialog()
              }}
            />
          }}
        </div>
      </FormattedCurrency.Provider>
    }
  | None => React.null
  }
}
