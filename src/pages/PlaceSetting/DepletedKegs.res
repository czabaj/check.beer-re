type classesType = {detailButtonCell: string, emptyTableMessage: string, table: string}
@module("./DepletedKegs.module.css") external classes: classesType = "default"

@genType @react.component
let make = (
  ~maybeFetchMoreDepletedKegs: option<unit => unit>,
  ~maybeDepletedKegs: option<array<Db.kegConverted>>,
) => {
  <SectionWithHeader
    buttonsSlot={React.null} headerId="depleted_kegs" headerSlot={React.string("Dopité sudy")}>
    {switch maybeDepletedKegs {
    | None =>
      <p className=classes.emptyTableMessage>
        <LoadingInline />
      </p>
    | Some([]) =>
      <p className=classes.emptyTableMessage>
        {React.string("Zde bude přehled dopitých sudů, zatím jste žádný nedopili 🤷‍♂️")}
      </p>
    | Some(kegs) =>
      <>
        <table className={classes.table}>
          <thead>
            <tr>
              <th scope="col"> {React.string("No.")} </th>
              <th scope="col"> {React.string("Pivo")} </th>
              <th scope="col"> {React.string("Objem")} </th>
              <th scope="col"> {React.string("Vypito")} </th>
              <th scope="col"> {React.string("Ztráty")} </th>
              <th scope="col"> {React.string("Naskladněno")} </th>
              <th scope="col"> {React.string("Naraženo")} </th>
              <th scope="col"> {React.string("Dopito")} </th>
              <th scope="col"> {React.string("Cena sudu")} </th>
              <th scope="col"> {React.string("Cena velkého piva")} </th>
              <th scope="col"> {React.string("Efektivita")} </th>
            </tr>
          </thead>
          <tbody>
            {kegs
            ->Array.map(keg => {
              let volume = keg.milliliters
              let kegId = Db.getUid(keg)
              let effectivity = keg.consumptionsSum->Float.fromInt /. volume->Float.fromInt
              let priceLargeBeer =
                (keg.price->Int.toFloat /. keg.milliliters->Int.toFloat *. 500.0)->Int.fromFloat

              <tr key={kegId}>
                <th scope="row"> {React.string(keg.serialFormatted)} </th>
                <td> {React.string(keg.beer)} </td>
                <td>
                  <FormattedVolume milliliters=volume />
                </td>
                <td>
                  <FormattedVolume milliliters=keg.consumptionsSum />
                </td>
                <td>
                  <FormattedVolume milliliters={volume - keg.consumptionsSum} />
                </td>
                <td>
                  <ReactIntl.FormattedDate value={keg.createdAt->Firebase.Timestamp.toDate} />
                </td>
                <td>
                  <ReactIntl.FormattedDate
                    value={Db.kegFirstConsumptionTimestamp(keg)
                    ->Option.map(Js.Date.fromFloat)
                    ->Option.getExn}
                  />
                </td>
                <td>
                  <ReactIntl.FormattedDate
                    value={keg.depletedAt->Null.toOption->Option.getExn->Firebase.Timestamp.toDate}
                  />
                </td>
                <td>
                  <FormattedCurrency value={keg.price} />
                </td>
                <td>
                  <FormattedCurrency
                    value={(priceLargeBeer->Int.toFloat /. effectivity)->Int.fromFloat}
                  />
                </td>
                <td>
                  <FormattedPercent value={effectivity} />
                </td>
              </tr>
            })
            ->React.array}
          </tbody>
        </table>
        {switch maybeFetchMoreDepletedKegs {
        | None => React.null
        | Some(fetchMore) =>
          <button className={Styles.button.base} onClick={_ => fetchMore()} type_="button">
            {React.string("Načíst další")}
          </button>
        }}
      </>
    }}
  </SectionWithHeader>
}
