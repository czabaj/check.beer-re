type classesType = {
  deleteButton: string,
  table: string,
}

@module("./TableConsumptions.module.css") external classes: classesType = "default"

@react.component
let make = (
  ~ariaLabelledby=?,
  ~formatConsumption,
  ~onDeleteConsumption,
  ~unfinishedConsumptions: array<Db.userConsumption>,
) => {
  <table ?ariaLabelledby className={`${classes.table} ${Styles.table.inDialog}`}>
    <thead>
      <tr className={Styles.utility.srOnly}>
        <th scope="col"> {React.string("Pivo")} </th>
        <th scope="col"> {React.string("Kdy")} </th>
        <th scope="col"> {React.string("Objem")} </th>
        <th scope="col">
          <span className={Styles.utility.srOnly}> {React.string("Akce")} </span>
        </th>
      </tr>
    </thead>
    <tbody>
      {unfinishedConsumptions
      ->Array.map(consumption => {
        let createdAt = consumption.createdAt->Js.Date.toISOString
        <tr key={createdAt}>
          <th scope="row"> {React.string(consumption.beer)} </th>
          <td>
            <FormattedDateTimeShort value=consumption.createdAt />
          </td>
          <td> {formatConsumption(consumption)->React.string} </td>
          <td>
            <button
              className={`${classes.deleteButton} ${Styles.button.sizeExtraSmall}`}
              onClick={_ => onDeleteConsumption(consumption)}
              type_="button">
              {React.string("🗑️ Smáznout")}
            </button>
          </td>
        </tr>
      })
      ->React.array}
    </tbody>
  </table>
}
