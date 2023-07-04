type classesType = {root: string}
@module("./KegDetail.module.css") external classes: classesType = "default"

@react.component
let make = (
  ~keg: Db.kegConverted,
  ~place: Db.placeConverted,
  ~onDeleteConsumption,
  ~onDismiss,
  ~onPreviousKeg,
  ~onNextKeg,
) => {
  let firstConsumption =
    keg.consumptions
    ->Belt.Map.String.keysToArray
    ->Belt.Array.reduce(None, (min, timestampStr) => {
      switch min {
      | None => timestampStr->Float.fromString
      | Some(timestamp) => Some(Math.min(timestamp, timestampStr->Float.fromString->Option.getExn))
      }
    })
  let priceLargeBeer =
    (keg.price->Int.toFloat /. keg.milliliters->Int.toFloat *. 500.0)->Int.fromFloat
  <DialogCycling
    className=classes.root
    header={`${keg.serialFormatted} ${keg.beer}`}
    onDismiss
    onNext=onNextKeg
    onPrevious=onPreviousKeg
    visible=true>
    <dl className={`reset ${Styles.descriptionListClasses.inline}`}>
      <div>
        <dt> {React.string("objem")} </dt>
        <dd>
          <FormattedVolume milliliters={keg.milliliters} />
        </dd>
      </div>
      <div>
        <dt> {React.string("naskladněno dne")} </dt>
        <dd>
          <FormattedDateTime value={keg.createdAt->Firebase.Timestamp.toDate} />
        </dd>
      </div>
      <div>
        <dt> {React.string("za")} </dt>
        <dd>
          <FormattedCurrency value={keg.price} />
        </dd>
      </div>
      <div>
        <dt> {React.string("t.j. velké pivo za")} </dt>
        <dd>
          <FormattedCurrency value={priceLargeBeer} />
        </dd>
      </div>
      {switch firstConsumption {
      | None => React.null
      | Some(timestamp) =>
        <div>
          <dt> {React.string("první odtoč dne")} </dt>
          <dd>
            <FormattedDateTime value={timestamp->Js.Date.fromFloat} />
          </dd>
        </div>
      }}
      {switch keg.depletedAt->Null.toOption {
      | None => React.null
      | Some(depletedAt) => {
          let effectivity = keg.consumptionsSum->Int.toFloat /. keg.milliliters->Int.toFloat
          <>
            <div>
              <dt> {React.string("dopito")} </dt>
              <dd>
                <FormattedDateTime value={depletedAt->Firebase.Timestamp.toDate} />
              </dd>
            </div>
            <div>
              <dt> {React.string("ze sudu se vytočilo")} </dt>
              <dd>
                <FormattedVolume milliliters={keg.milliliters} />
              </dd>
            </div>
            <div>
              <dt> {React.string("efektivita")} </dt>
              <dd> {React.string(`${effectivity->Float.toFixedWithPrecision(~digits=2)}%`)} </dd>
            </div>
            <div>
              <dt> {React.string("výsledná cena za velké pivo")} </dt>
              <dd>
                <FormattedCurrency
                  value={(priceLargeBeer->Int.toFloat /. effectivity)->Int.fromFloat}
                />
              </dd>
            </div>
          </>
        }
      }}
    </dl>
    <table className={Styles.tableClasses.consumptions}>
      <caption> {React.string("Natočená piva")} </caption>
      <thead>
        <tr>
          <th scope="col"> {React.string("Jméno")} </th>
          <th scope="col"> {React.string("Objem")} </th>
          <th scope="col"> {React.string("Kdy")} </th>
          <th scope="col">
            <span className={Styles.utilityClasses.srOnly}> {React.string("Akce")} </span>
          </th>
        </tr>
      </thead>
      <tbody>
        {keg.consumptions
        ->Belt.Map.String.toArray
        // The map is sorted by timestamp ascending, we want descending
        ->Array.reverse
        ->Array.map(((timestampStr, consumption)) => {
          let person = place.personsAll->Belt.Map.String.getExn(consumption.person.id)
          let createdData = timestampStr->Float.fromString->Option.getExn->Js.Date.fromFloat
          <tr>
            <td> {React.string(person.name)} </td>
            <td>
              <FormattedVolume milliliters=consumption.milliliters />
            </td>
            <td>
              <FormattedDateTime value={createdData} />
            </td>
            <td>
              {keg.depletedAt !== Null.null
                ? React.null
                : <button
                    className={`${Styles.buttonClasses.button}`}
                    onClick={_ => onDeleteConsumption(timestampStr)}
                    type_="button">
                    {React.string("🗑️ Smáznout")}
                  </button>}
            </td>
          </tr>
        })
        ->React.array}
      </tbody>
    </table>
  </DialogCycling>
}
