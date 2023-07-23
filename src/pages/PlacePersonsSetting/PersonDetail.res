type classesType = {root: string}
@module("./PersonDetail.module.css") external classes: classesType = "default"

type dialogState =
  | Hidden
  | ConfirmDeletePerson
  | AddTransaction

let byCreatedDesc = (
  a: FirestoreModels.financialTransaction,
  b: FirestoreModels.financialTransaction,
) => b.createdAt->Firebase.Timestamp.toMillis -. a.createdAt->Firebase.Timestamp.toMillis

@react.component
let make = (
  ~hasNext,
  ~hasPrevious,
  ~onDeleteConsumption,
  ~onDeletePerson,
  ~onDismiss,
  ~onNextPerson,
  ~onPreviousPerson,
  ~pendingTransactions: array<FirestoreModels.financialTransaction>,
  ~person: Db.personsAllRecord,
  ~personsAll: array<(string, Db.personsAllRecord)>,
  ~personId,
  ~placeId,
  ~unfinishedConsumptions: array<Db.userConsumption>,
) => {
  let firestore = Reactfire.useFirestore()
  let {data: maybePersonDoc} = Db.usePlacePersonDocumentStatus(
    ~options={idField: #uid, suspense: false},
    placeId,
    personId,
  )
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  <DialogCycling
    className={classes.root}
    hasNext
    hasPrevious
    header={person.name}
    onDismiss
    onNext=onNextPerson
    onPrevious=onPreviousPerson
    visible={true}>
    <section ariaLabel="Základní údaje">
      <dl className={`reset ${Styles.descriptionList.inline}`}>
        <div>
          <dt> {React.string("již od")} </dt>
          <dd>
            {switch maybePersonDoc {
            | None => <LoadingInline />
            | Some(personDoc) =>
              <FormattedDateTime value={personDoc.createdAt->Firebase.Timestamp.toDate} />
            }}
          </dd>
        </div>
        <div>
          <dt> {React.string("naposledy")} </dt>
          <dd>
            <FormattedDateTime value={person.recentActivityAt->Firebase.Timestamp.toDate} />
          </dd>
        </div>
        <div>
          <dt> {React.string("stav konta")} </dt>
          <dd>
            <FormattedCurrency format={FormattedCurrency.formatAccounting} value=person.balance />
          </dd>
        </div>
      </dl>
    </section>
    {unfinishedConsumptions->Array.length === 0
      ? <p>
          {React.string(`${person.name} nemá nezaúčtovaná piva.`)}
          {switch (pendingTransactions, maybePersonDoc) {
          | ([], Some({transactions: []})) =>
            <>
              {React.string(` Dokonce nemá ani účetní záznam. Pokud jste tuto osobu přidali omylem, můžete jí nyní `)}
              <button
                className={Styles.link.base}
                onClick={_ => setDialog(_ => ConfirmDeletePerson)}
                type_="button">
                {React.string("zcela odebrat z aplikace")}
              </button>
              {React.string(". S účetním záznamem to později již není možné ☝️")}
            </>
          | _ => React.null
          }}
        </p>
      : <TableConsumptions
          captionSlot={React.string("Nezaúčtované konzumace")}
          onDeleteConsumption
          unfinishedConsumptions
        />}
    <section ariaLabelledby="financial_transactions">
      <header>
        <h3 id="financial_transactions"> {React.string("Účetní záznamy")} </h3>
        {React.cloneElement(
          <button
            className={Styles.button.base}
            onClick={_ => setDialog(_ => AddTransaction)}
            type_="button">
            {React.string("Zaznamenat transakci")}
          </button>,
          personsAll->Array.length < 2
            ? {"disabled": true, "title": "Přidejte další osoby"}
            : Object.empty(),
        )}
      </header>
      {switch (pendingTransactions, maybePersonDoc) {
      | (_, None) => <LoadingInline />
      | ([], Some({transactions: []})) =>
        <p> {React.string("Tato osoba zatím nemá účetní záznamy.")} </p>
      | (pending, Some({transactions})) =>
        pending->Array.sort(byCreatedDesc)
        transactions->Array.sort(byCreatedDesc)
        <table ariaLabelledby="financial_transactions" className={Styles.table.inDialog}>
          <thead>
            <tr>
              <th scope="col"> {React.string("Datum")} </th>
              <th scope="col"> {React.string("Částka")} </th>
              <th scope="col"> {React.string("Poznámka")} </th>
            </tr>
          </thead>
          <tbody>
            {pending
            ->Array.map(pendingTransaction => {
              let createdDate = pendingTransaction.createdAt->Firebase.Timestamp.toDate
              <tr key={createdDate->Js.Date.getTime->Float.toString}>
                <td>
                  <FormattedDateTime value={createdDate} />
                </td>
                <td>
                  <FormattedCurrency value={pendingTransaction.amount} />
                </td>
                <td>
                  {switch pendingTransaction.keg->Null.toOption {
                  | None => React.null
                  | Some(kegSerial) =>
                    React.string(`Nezaúčtované: vklad za sud #${kegSerial->Int.toString}`)
                  }}
                </td>
              </tr>
            })
            ->React.array}
            {transactions
            ->Array.map(finalTransaction => {
              let createdDate = finalTransaction.createdAt->Firebase.Timestamp.toDate
              <tr key={createdDate->Js.Date.getTime->Float.toString}>
                <td>
                  <FormattedDateTime value={createdDate} />
                </td>
                <td>
                  <FormattedCurrency value={finalTransaction.amount} />
                </td>
                <td>
                  {switch (
                    finalTransaction.note->Null.toOption,
                    finalTransaction.keg->Null.toOption,
                    finalTransaction.amount > 0,
                  ) {
                  | (Some(note), _, _) => React.string(note)
                  | (_, Some(kegSerial), false) =>
                    React.string(`Konzumace ze sudu #${kegSerial->Int.toString}`)
                  | (_, Some(kegSerial), true) =>
                    React.string(`Věřitelství za sud #${kegSerial->Int.toString}`)
                  | (_, None, false) => React.string("Mimořádná srážka")
                  | (_, None, true) => React.string("Nabití kreditu")
                  | _ => React.null
                  }}
                </td>
              </tr>
            })
            ->React.array}
          </tbody>
        </table>
      }}
    </section>
    {switch dialogState {
    | Hidden => React.null
    | AddTransaction => {
        let highestBalanceNonCurrentPerson = personsAll->Array.reduce(None, (acc, item) => {
          let (itemId, {Db.balance: itemBalance}) = item
          if itemId === personId {
            // skip current person, it cannot be a counterparty
            acc
          } else {
            switch acc {
            | None => Some(item)
            | Some((_, {Db.balance: accBalance})) =>
              if accBalance >= itemBalance {
                acc
              } else {
                Some(item)
              }
            }
          }
        })
        <AddFinancialTransactions
          initialCounterParty={highestBalanceNonCurrentPerson
          ->Option.map(fst)
          ->Option.getWithDefault("")}
          onDismiss={hideDialog}
          onSubmit={async values => {
            await Db.Person.addFinancialTransaction(
              firestore,
              ~counterPartyId=values.person,
              ~placeId,
              ~personId,
              ~transaction={
                amount: values.amount,
                createdAt: Firebase.Timestamp.now(),
                keg: Null.null,
                note: values.note === "" ? Null.null : Null.make(values.note),
                person: Null.make(values.person),
              },
            )
            hideDialog()
          }}
          personId
          personName={person.name}
          personsAll
        />
      }
    | ConfirmDeletePerson =>
      <DialogConfirmation
        className={DialogConfirmation.classes.deleteConfirmation}
        heading="Odstranit osobu ?"
        onConfirm={() => {
          hideDialog()
          onDeletePerson()
        }}
        onDismiss={() => hideDialog()}
        visible=true>
        <p>
          {React.string(`Chystáte se odstranit osobu `)}
          <b> {React.string(person.name)} </b>
          {React.string(` z aplikace. Nemá žádnou historii konzumací ani účetní transakci. Chcete pokračovat?`)}
        </p>
      </DialogConfirmation>
    }}
  </DialogCycling>
}
