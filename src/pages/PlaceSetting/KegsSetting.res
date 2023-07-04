type classesType = {detailButtonCell: string, emptyTableMessage: string, table: string}
@module("./KegsSetting.module.css") external classes: classesType = "default"

type dialogState = Hidden | AddKeg | KegDetail(string)

type dialogEvent = Hide | ShowAddKeg | ShowKegDetail(string)

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddKeg => AddKeg
  | ShowKegDetail(kegId) => KegDetail(kegId)
  }
}

@react.component
let make = (~chargedKegs: array<Db.kegConverted>, ~place, ~placeId) => {
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
                <ButtonDetail onClick={_ => sendDialog(ShowKegDetail(kegId))} title="Karta sudu" />
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
                consumptions: Js.Dict.empty(),
                createdAt: Firebase.Timestamp.now(),
                depletedAt: Null.null,
                milliliters: (liters *. 1000.0)->Int.fromFloat,
                price: (price *. minorUnit)->Int.fromFloat,
                recentConsumptionAt: Null.null,
                serial,
              },
            )
          )->ignore
          hideDialog()
        }}
        placeId
      />
    | KegDetail(kegId) => {
        let currentIdx =
          chargedKegs->Array.findIndex(keg => Db.getUid(keg)->Option.getExn === kegId)
        let hasNext = currentIdx !== -1 && currentIdx < Array.length(chargedKegs) - 1
        let hasPrevious = currentIdx > 0
        let handleCycle = increase => {
          let allowed = increase ? hasNext : hasPrevious
          if allowed {
            let nextIdx = currentIdx + (increase ? 1 : -1)
            let nextKegId = chargedKegs->Belt.Array.getExn(nextIdx)->Db.getUid->Option.getExn
            sendDialog(ShowKegDetail(nextKegId))
          }
        }
        let keg = chargedKegs->Belt.Array.getExn(currentIdx)
        <KegDetail
          hasNext
          hasPrevious
          keg
          onDeleteConsumption={consumptionId => {
            Db.deleteConsumption(firestore, placeId, kegId, consumptionId)->ignore
          }}
          onDeleteKeg={_ => {
            Db.deleteKeg(firestore, placeId, kegId)->ignore
            hideDialog()
          }}
          onDismiss={hideDialog}
          onNextKeg={_ => handleCycle(true)}
          onPreviousKeg={_ => handleCycle(false)}
          place
        />
      }
    }}
  </SectionWithHeader>
}
