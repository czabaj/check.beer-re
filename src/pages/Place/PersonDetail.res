type classesType = {root: string}
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
  ~hasNext,
  ~hasPrevious,
  ~onDeleteConsumption,
  ~onDeletePerson,
  ~onDismiss,
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
    hasNext
    hasPrevious
    header={person.name}
    onDismiss
    onNext=onNextPerson
    onPrevious=onPreviousPerson
    visible={true}>
    <section ariaLabel="Základní údaje">
      <dl className={`reset ${Styles.descriptionListClasses.inline}`}>
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
        : <table className={Styles.tableClasses.consumptions}>
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
                    <FormattedVolume milliliters=consumption.milliliters />
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
          className={DialogConfirmation.classes.deleteConfirmation}
          heading="Odstranit osobu ?"
          onConfirm={() => {
            onDismiss()
            onDeletePerson()
          }}
          onDismiss={() => setShowDeletePersonConfirmation(_ => false)}
          visible=true>
          <p>
            {React.string(`Chystáte se odstranit osobu `)}
            <b> {React.string(person.name)} </b>
            {React.string(` z aplikace. Nemá žádnou historii konzumací ani účetních transakcí. Chcete pokračovat?`)}
          </p>
        </DialogConfirmation>}
  </DialogCycling>
}
