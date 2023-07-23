type classesType = {table: string}

@module("./PlacePersonsSetting.module.css") external classes: classesType = "default"

type dialogState =
  | Hidden
  | AddPerson
  | PersonDetail({personId: string, person: Db.personsAllRecord})

let pageDataRx = (firestore, placeId) => {
  open Rxjs
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)
  let allChargedKegsRx = Db.allChargedKegsRx(firestore, placeId)
  let unfinishedConsumptionsByUserRx = allChargedKegsRx->pipe(
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
  let pendingTransactionsByUserRx = allChargedKegsRx->pipe(
    map((chargedKegs: array<Db.kegConverted>, _) => {
      let kegByDonor = Map.make()
      chargedKegs->Array.forEach(keg => {
        keg.donors
        ->Js.Dict.entries
        ->Array.forEach(
          ((personId, amount)) => {
            let transaction: FirestoreModels.financialTransaction = {
              amount,
              createdAt: keg.createdAt,
              keg: Null.make(keg.serial),
              note: Null.null,
              person: Null.null,
            }
            switch kegByDonor->Map.get(personId) {
            | Some(kegs) => kegs->Array.push(transaction)
            | None => kegByDonor->Map.set(personId, [transaction])
            }
          },
        )
      })
      kegByDonor
    }),
  )
  let personsAllRx = Db.PersonsIndex.allEntriesSortedRx(firestore, ~placeId)
  combineLatest4(placeRx, personsAllRx, unfinishedConsumptionsByUserRx, pendingTransactionsByUserRx)
}

@react.component
let make = (~placeId) => {
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId=`Page_PlacePersonsSetting_${placeId}`,
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  switch pageDataStatus.data {
  | Some((place, personsAll, unfinishedConsumptionsByUser, pendingTransactionsByUser)) =>
    <FormattedCurrency.Provider value={place.currency}>
      <div className=Styles.page.narrow>
        <PlaceHeader
          buttonRightSlot={React.null} createdTimestamp={place.createdAt} placeName={place.name}
        />
        <main>
          <SectionWithHeader
            buttonsSlot={<button
              className={Styles.button.base}
              type_="button"
              onClick={_ => setDialog(_ => AddPerson)}>
              {React.string("Přidat osobu")}
            </button>}
            headerId="persons_accounts"
            headerSlot={React.string("Účetnictví")}>
            <table
              ariaLabelledby="persons_accounts"
              className={`${Styles.table.stretch} ${classes.table}`}>
              <thead>
                <tr>
                  <th scope="col"> {React.string("Návštěvník")} </th>
                  <th scope="col"> {React.string("Poslední aktivita")} </th>
                  <th scope="col"> {React.string("Bilance")} </th>
                </tr>
              </thead>
              <tbody>
                {personsAll
                ->Array.map(((personId, person)) => {
                  <tr key=personId>
                    <th scope="row">
                      {React.string(person.name)}
                      <button
                        className={Styles.utility.breakout}
                        onClick={_ => setDialog(_ => PersonDetail({personId, person}))}
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
          let currentIdx = personsAll->Array.findIndex(((id, _)) => id === personId)
          if currentIdx === -1 {
            // Possibly, the person was deleted on the backend best to close the dialog
            hideDialog()
            React.null
          } else {
            let hasNext = currentIdx < Array.length(personsAll) - 1
            let hasPrevious = currentIdx > 0
            let handleCycle = increase => {
              let allowed = increase ? hasNext : hasPrevious
              if allowed {
                let nextIdx = currentIdx + (increase ? 1 : -1)
                let (nextPersonId, nextPerson) = personsAll->Belt.Array.getExn(nextIdx)
                setDialog(_ => PersonDetail({
                  person: nextPerson,
                  personId: nextPersonId,
                }))
              }
            }
            let unfinishedConsumptions =
              unfinishedConsumptionsByUser->Map.get(personId)->Option.getWithDefault([])
            <PersonDetail
              hasNext
              hasPrevious
              onDeleteConsumption={consumption => {
                Db.Keg.deleteConsumption(
                  firestore,
                  ~placeId,
                  ~kegId=consumption.kegId,
                  ~consumptionId=consumption.consumptionId,
                )->ignore
              }}
              onDeletePerson={_ => {
                Db.Person.delete(firestore, ~placeId, ~personId)->ignore
              }}
              onDismiss={hideDialog}
              onNextPerson={_ => handleCycle(true)}
              onPreviousPerson={_ => handleCycle(false)}
              pendingTransactions={pendingTransactionsByUser
              ->Map.get(personId)
              ->Option.getWithDefault([])}
              person
              personId
              personsAll
              placeId
              unfinishedConsumptions={unfinishedConsumptions}
            />
          }
        | AddPerson =>
          <PersonAddPersonsSetting
            existingNames={personsAll->Array.map(((_, person)) => person.name)}
            onDismiss={hideDialog}
            onSubmit={async values => {
              await Db.Person.add(firestore, ~placeId, ~personName=values.name)
              hideDialog()
            }}
          />
        }}
      </div>
    </FormattedCurrency.Provider>
  | None => React.null
  }
}
