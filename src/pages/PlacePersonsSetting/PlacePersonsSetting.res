type classesType = {table: string}

@module("./PlacePersonsSetting.module.css") external classes: classesType = "default"

type dialogState =
  | Hidden
  | AddPerson
  | PersonDetail({personId: string, person: Db.personsAllRecord})

let pageDataRx = (auth, firestore, placeId) => {
  open Rxjs
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)->op(keepSome)
  let allChargedKegsRx = Db.allChargedKegsRx(firestore, placeId)
  let unfinishedConsumptionsByUserRx = allChargedKegsRx->op(
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
  let pendingTransactionsByUserRx = allChargedKegsRx->op(
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
  let currentUserRx = Rxfire.user(auth)->op(keepMap(Null.toOption))
  combineLatest5(
    placeRx,
    personsAllRx,
    unfinishedConsumptionsByUserRx,
    pendingTransactionsByUserRx,
    currentUserRx,
  )
}

@react.component
let make = (~placeId) => {
  let auth = Reactfire.useAuth()
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId=`Page_PlacePersonsSetting_${placeId}`,
    ~source=pageDataRx(auth, firestore, placeId),
  )
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  switch pageDataStatus.data {
  | Some((
      place,
      personsAll,
      unfinishedConsumptionsByUser,
      pendingTransactionsByUser,
      currentUser,
    )) =>
    let currentUserRole = place.users->Dict.get(currentUser.uid)->Option.getExn
    let isUserAuthorized = UserRoles.isAuthorized(currentUserRole, ...)
    if !isUserAuthorized(UserRoles.Admin) {
      Exn.raiseError(`Insufficient permissions to view this page`)
    }
    let formatConsumption = BackendUtils.getFormatConsumption(place.consumptionSymbols)
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
              {React.string("Přidat hosta")}
            </button>}
            headerId="persons_accounts"
            headerSlot={React.string("Účetnictví")}>
            <table
              ariaLabelledby="persons_accounts"
              className={`${Styles.table.stretch} ${classes.table}`}>
              <thead>
                <tr>
                  <th scope="col"> {React.string("Host")} </th>
                  <th scope="col"> {React.string("Role")} </th>
                  <th scope="col"> {React.string("Naposledy")} </th>
                  <th scope="col"> {React.string("Konto")} </th>
                </tr>
              </thead>
              <tbody>
                {personsAll
                ->Array.map(((personId, person)) => {
                  /* TODO: tr.onClick is not accessible, but breakout buttons not work since <tr> cannot have relative
                   positioning in Safari @see https://github.com/w3c/csswg-drafts/issues/1899 */
                  <tr key=personId onClick={_ => setDialog(_ => PersonDetail({personId, person}))}>
                    <th scope="row"> {React.string(person.name)} </th>
                    <td>
                      {person.userId
                      ->Null.toOption
                      ->Option.flatMap(userId => place.users->Dict.get(userId))
                      ->Option.flatMap(UserRoles.roleFromInt)
                      ->Option.map(UserRoles.roleI18n)
                      ->Option.mapOr(React.null, React.string)}
                    </td>
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
              unfinishedConsumptionsByUser->Map.get(personId)->Option.getOr([])
            <PersonDetail
              formatConsumption
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
              ->Option.getOr([])}
              person
              personId
              personsAll
              place
              placeId
              unfinishedConsumptions={unfinishedConsumptions}
            />
          }
        | AddPerson =>
          <PersonAddPersonsSetting
            existingNames={personsAll->Array.map(((_, person)) => person.name)}
            onDismiss={hideDialog}
            onSubmit={values => {
              Db.Person.add(firestore, ~placeId, ~personName=values.name)->ignore
              hideDialog()
            }}
          />
        }}
      </div>
    </FormattedCurrency.Provider>
  | None => React.null
  }
}
