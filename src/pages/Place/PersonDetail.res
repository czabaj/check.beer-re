type classesType = {root: string}
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
  ~person: Db.personsAllRecord,
  ~unfinishedConsumptions: array<unfinishedConsumptionsRecord>,
) => {
  <Dialog className={classes.root} visible={true}>
    <header>
      <h3> {React.string(person.name)} </h3>
    </header>
    <section> {React.string("Dluží/Má předplaceno")} </section>
    <section ariaLabelledby="unfinished_consumptions">
      {unfinishedConsumptions->Array.length === 0
        ? <p> {React.string("Prázdné")} </p>
        : <table>
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
                    <ReactIntl.FormattedDate
                      year=#numeric
                      month=#numeric
                      day=#numeric
                      hour=#numeric
                      minute=#numeric
                      value=consumption.createdAt
                    />
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
    <footer>
      <button className={`${Styles.buttonClasses.button}`} type_="button">
        {React.string("⬅️")}
      </button>
      <button className={`${Styles.buttonClasses.button}`} type_="button">
        {React.string("➡️")}
      </button>
      <button className={`${Styles.buttonClasses.button}`} onClick={onDismiss}>
        {React.string("Zavřít")}
      </button>
    </footer>
  </Dialog>
}
