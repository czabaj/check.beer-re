type classesType = {detailButtonCell: string, emptyTableMessage: string, table: string}
@module("./ChargedKegsSetting.module.css") external classes: classesType = "default"

@react.component
let make = (~chargedKegs: array<Db.kegConverted>, ~onAddNewKeg, ~onKegDetail) => {
  <SectionWithHeader
    buttonsSlot={<button
      className={Styles.buttonClasses.button} onClick={_ => onAddNewKeg()} type_="button">
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
            <th scope="col"> {React.string("Naskladněno")} </th>
            <th scope="col"> {React.string("Cena")} </th>
            <th scope="col"> {React.string("Objem")} </th>
            <th id="remaining_th" scope="col"> {React.string("Zbývá")} </th>
            <th scope="col">
              <span className={Styles.utilityClasses.srOnly}> {React.string("Akce")} </span>
            </th>
          </tr>
        </thead>
        <tbody>
          {kegs
          ->Array.map(keg => {
            let volume = keg.milliliters
            let kegId = Db.getUid(keg)->Option.getExn
            <tr key={kegId}>
              <th scope="row"> {React.string(keg.serialFormatted)} </th>
              <td> {React.string(keg.beer)} </td>
              <td>
                {<ReactIntl.FormattedDate value={keg.createdAt->Firebase.Timestamp.toDate} />}
              </td>
              <td>
                <FormattedCurrency value={keg.price} />
              </td>
              <td>
                <FormattedVolume milliliters=volume />
              </td>
              <td>
                <meter
                  ariaLabelledby="remaining_th"
                  min="0"
                  max={volume->Int.toString}
                  low={volume / 5}
                  optimum={volume / 2}
                  value={(volume - keg.consumptionsSum)->Int.toString}>
                  {React.string(
                    `${Int.toString(volume / 1000)} / ${Int.toString(volume / 1000)} litrů`,
                  )}
                </meter>
              </td>
              <td className={classes.detailButtonCell}>
                <ButtonDetail onClick={_ => onKegDetail(kegId)} title="Karta sudu" />
              </td>
            </tr>
          })
          ->React.array}
        </tbody>
      </table>
    }}
  </SectionWithHeader>
}
