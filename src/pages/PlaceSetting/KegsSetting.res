type classesType = {emptyTableMessage: string, table: string}
@module("./KegsSetting.module.css") external classes: classesType = "default"

type dialogState = Hidden | AddKeg

type dialogEvent = Hide | ShowAddKeg

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddKeg => AddKeg
  }
}

@react.component
let make = (~chargedKegs: array<Db.kegConverted>, ~placeId) => {
  let firestore = Firebase.useFirestore()
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  let {minorUnit} = FormattedCurrency.useCurrency()

  <SectionWithHeader
    buttonsSlot={<button
      className={Styles.buttonClasses.button} onClick={_ => sendDialog(ShowAddKeg)} type_="button">
      {React.string("Přidat sud")}
    </button>}
    headerId="kegs-setting"
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
          </tr>
        </thead>
        <tbody>
          {kegs
          ->Array.map(keg => {
            let volume = keg.milliliters
            <tr key={keg.serial->Int.toString}>
              <th scope="row"> {React.string(keg.serialFormatted)} </th>
              <td> {React.string(keg.beer)} </td>
              <td>
                {<ReactIntl.FormattedDate value={keg.createdAt->Firebase.Timestamp.toDate} />}
              </td>
              <td>
                <FormattedCurrency value={keg.priceNew} />
              </td>
              <td> {React.string(`${Int.toString(volume / 1000)} l`)} </td>
              <td>
                <meter
                  ariaLabelledby="remaining_th"
                  min="0"
                  max={volume->Int.toString}
                  low={volume / 5}
                  high={volume / 5 * 4}
                  optimum={volume / 2}
                  value={(volume - keg.consumptionsSum)->Int.toString}>
                  {React.string(
                    `${Int.toString(volume / 1000)} / ${Int.toString(volume / 1000)} litrů`,
                  )}
                </meter>
              </td>
            </tr>
          })
          ->React.array}
        </tbody>
      </table>
    }}
    {switch dialogState {
    | Hidden => React.null
    | AddKeg =>
      <KegAddNew
        onDismiss={hideDialog}
        onSubmit={async ({beer, liters, price, serial}) => {
          (
            await Firebase.addDoc(
              Db.placeKegsCollection(firestore, placeId),
              {
                beer,
                consumptions: [],
                createdAt: Firebase.Timestamp.now(),
                depletedAt: Null.null,
                milliliters: (liters *. 1000.0)->Int.fromFloat,
                priceEnd: Null.null,
                priceNew: (price *. minorUnit)->Int.fromFloat,
                recentConsumptionAt: Null.null,
                serial,
              },
            )
          )->ignore
          hideDialog()
        }}
        placeId
      />
    }}
  </SectionWithHeader>
}
