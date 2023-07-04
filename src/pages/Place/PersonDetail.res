type classesType = {
  basicsDescriptionList: string,
  deletePersonDialog: string,
  root: string,
  scrollContent: string,
  unfinishedConcumptionsTable: string,
}
@module("./PersonDetail.module.css") external classes: classesType = "default"

type unfinishedConsumptionsRecord = {
  consumptionId: string,
  kegId: string,
  beer: string,
  milliliters: int,
  createdAt: Js.Date.t,
}

@react.component
let make = (
  ~onDismiss,
  ~onDeleteConsumption,
  ~onDeletePerson,
  ~onNextPerson,
  ~onPreviousPerson,
  ~person: Db.personsAllRecord,
  ~personId,
  ~placeId,
  ~unfinishedConsumptions: array<unfinishedConsumptionsRecord>,
) => {
  let {data: maybePersonDoc} = Db.usePlacePersonDocumentStatus(
    ~options={suspense: false},
    placeId,
    personId,
  )
  let (showDeletePersonConfirmation, setShowDeletePersonConfirmation) = React.useState(_ => false)
  <DialogCycling
    className={classes.root}
    header={person.name}
    onDismiss
    onNext=onNextPerson
    onPrevious=onPreviousPerson
    visible={true}>
    <section ariaLabel="Základní údaje">
      <dl className={`reset ${classes.basicsDescriptionList}`}>
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
            {switch maybePersonDoc {
            | None => <LoadingInline />
            | Some(personDoc) =>
              <FormattedCurrency
                format={FormattedCurrency.formatAccounting} value=personDoc.balance
              />
            }}
          </dd>
        </div>
      </dl>
    </section>
    <section ariaLabelledby="unfinished_consumptions">
      {unfinishedConsumptions->Array.length === 0
        ? <p>
            {React.string(`${person.name} nemá nezaúčtovaná piva.`)}
            {switch maybePersonDoc {
            | Some({transactions: []}) =>
              <>
                {React.string(` Dokonce nemá ani účetní záznam. Pokud jste tuto osobu přidali omylem, můžete jí nyní `)}
                <button
                  className={Styles.linkClasses.base}
                  onClick={_ => setShowDeletePersonConfirmation(_ => true)}
                  type_="button">
                  {React.string("zcela odebrat z aplikace")}
                </button>
                {React.string(". S účetním záznamem to později již není možné ☝️")}
              </>
            | _ => React.null
            }}
          </p>
        : <table className={classes.unfinishedConcumptionsTable}>
            <caption> {React.string("Nezaúčtovaná piva")} </caption>
            <thead>
              <tr>
                <th scope="col"> {React.string("Pivo")} </th>
                <th scope="col"> {React.string("Objem")} </th>
                <th scope="col"> {React.string("Kdy")} </th>
                <th scope="col">
                  <span className={Styles.utilityClasses.srOnly}> {React.string("Akce")} </span>
                </th>
              </tr>
            </thead>
            <tbody>
              {unfinishedConsumptions
              ->Array.map(consumption => {
                let createdAt = consumption.createdAt->Js.Date.toISOString
                <tr key={createdAt}>
                  <td> {React.string(consumption.beer)} </td>
                  <td>
                    {React.string(
                      `${(consumption.milliliters->Int.toFloat /. 1000.0)
                          ->Float.toFixedWithPrecision(~digits=1)} L`,
                    )}
                  </td>
                  <td>
                    <FormattedDateTime value=consumption.createdAt />
                  </td>
                  <td>
                    <button
                      className={`${Styles.buttonClasses.button}`}
                      onClick={_ => onDeleteConsumption(consumption)}
                      type_="button">
                      {React.string("🗑️ Smáznout")}
                    </button>
                  </td>
                </tr>
              })
              ->React.array}
            </tbody>
          </table>}
    </section>
    {!showDeletePersonConfirmation
      ? React.null
      : <DialogConfirmation
          className={classes.deletePersonDialog}
          heading="Odstranit osobu ?"
          onConfirm={() => {
            onDismiss()
            onDeletePerson()
          }}
          onDismiss={() => setShowDeletePersonConfirmation(_ => false)}
          visible=showDeletePersonConfirmation>
          <p>
            {React.string(`Chystáte se odstranit osobu `)}
            <b> {React.string(person.name)} </b>
            {React.string(` z aplikace. Nemá žádnou historii konzumací ani účetních transakcí. Chcete pokračovat?`)}
          </p>
        </DialogConfirmation>}
  </DialogCycling>
}
