type classesType = {
  basicsDescriptionList: string,
  root: string,
  scrollContent: string,
  unfinishedConcumptionsTable: string,
}
@module("./PersonDetail.module.css") external classes: classesType = "default"

type unfinishedConsumptionsRecord = {
  kegId: string,
  beer: string,
  milliliters: int,
  createdAt: Js.Date.t,
}

@react.component
let make = (
  ~onDismiss,
  ~onDeleteConsumption,
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
  <Dialog className={classes.root} visible={true}>
    <header>
      <h3> {React.string(person.name)} </h3>
      <button className={`${Styles.buttonClasses.button}`} onClick=onPreviousPerson type_="button">
        {React.string("⬅️ Předchozí")}
      </button>
      <button className={`${Styles.buttonClasses.button}`} onClick=onNextPerson type_="button">
        {React.string("Následující ➡️")}
      </button>
    </header>
    <div className={classes.scrollContent}>
      <section ariaLabel="Základní údaje">
        <dl className={`reset ${classes.basicsDescriptionList}`}>
          <div>
            <dt> {React.string("již od")} </dt>
            <dd>
              {switch maybePersonDoc {
              | None => React.string("načítám…")
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
              | None => React.string("načítám…")
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
          ? <p> {React.string("Prázdné")} </p>
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
    </div>
    <footer>
      <button className={`${Styles.buttonClasses.button}`} onClick={onDismiss}>
        {React.string("Zavřít")}
      </button>
    </footer>
  </Dialog>
}
