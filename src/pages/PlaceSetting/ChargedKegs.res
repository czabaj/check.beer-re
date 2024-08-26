type classesType = {emptyTableMessage: string, table: string}
@module("./ChargedKegs.module.css") external classes: classesType = "default"

@react.component
let make = (~chargedKegs: array<Db.kegConverted>, ~onAddNewKeg, ~onKegDetail) => {
  <SectionWithHeader
    buttonsSlot={<button className={Styles.button.base} onClick={_ => onAddNewKeg()} type_="button">
      {React.string("Přidat sud")}
    </button>}
    headerId="charged_kegs_setting"
    headerSlot={React.string("Sudy na skladě")}>
    {switch chargedKegs {
    | [] =>
      <div className={classes.emptyTableMessage}>
        {React.string("Naskladni sudy tlačítkem ⤴")}
      </div>
    | kegs =>
      <table className={classes.table}>
        <thead>
          <tr>
            <th scope="col"> {React.string("No.")} </th>
            <th scope="col"> {React.string("Pivo")} </th>
            <th scope="col"> {React.string("Objem")} </th>
            <th scope="col"> {React.string("Naskladněno")} </th>
            <th scope="col"> {React.string("Cena")} </th>
            <th id="remaining_th" scope="col"> {React.string("Zbývá")} </th>
          </tr>
        </thead>
        <tbody>
          {kegs
          ->Array.map(keg => {
            let kegId = Db.getUid(keg)
            let volume = keg.milliliters
            <tr key={kegId}>
              <th scope="row">
                {React.string(keg.serialFormatted)}
                <button
                  className={Styles.utility.breakout}
                  onClick={_ => onKegDetail(kegId)}
                  title="Karta sudu"
                  type_="button"
                />
              </th>
              <td> {React.string(keg.beer)} </td>
              <td>
                <FormattedVolume milliliters=volume />
              </td>
              <td>
                <ReactIntl.FormattedDate value={keg.createdAt->Firebase.Timestamp.toDate} />
              </td>
              <td>
                <FormattedCurrency value={keg.price} />
              </td>
              <td>
                <MeterKeg ariaLabelledby="remaining_th" keg />
              </td>
            </tr>
          })
          ->React.array}
        </tbody>
      </table>
    }}
  </SectionWithHeader>
}
