@react.component
let make = (
  ~ariaLabelledby=?,
  ~captionSlot=?,
  ~onDeleteConsumption,
  ~unfinishedConsumptions: array<Db.userConsumption>,
) => {
  <table ?ariaLabelledby className={Styles.table.consumptions}>
    {switch captionSlot {
    | Some(slot) => <caption> {slot} </caption>
    | None => React.null
    }}
    <thead>
      <tr>
        <th scope="col"> {React.string("Pivo")} </th>
        <th scope="col"> {React.string("Objem")} </th>
        <th scope="col"> {React.string("Kdy")} </th>
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
          <td> {React.string(consumption.beer)} </td>
          <td>
            <FormattedVolume milliliters=consumption.milliliters />
          </td>
          <td>
            <FormattedDateTime value=consumption.createdAt />
          </td>
          <td>
            <button
              className={`${Styles.button.button}`}
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
