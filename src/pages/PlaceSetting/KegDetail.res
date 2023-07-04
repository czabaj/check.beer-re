@react.component
let make = (~keg: Db.kegConverted, ~onDismiss, ~onPreviousKeg, ~onNextKeg) => {
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
    {React.string(
      "Naraženo, naskladněno, cena nákup, cena finální, všechny konzumace, možnost odstranit pokud je nedotčený, ...",
    )}
  </DialogCycling>
}
