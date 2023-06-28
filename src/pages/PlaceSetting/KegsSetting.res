type classesType = {emptyList: string, root: string}

@module("./SettingSection.module.css") external classes: classesType = "default"

type dialogState = Hidden | AddKeg

type dialogEvent = Hide | ShowAddKeg

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddKeg => AddKeg
  }
}

@react.component
let make = (~kegs: array<FirestoreModels.keg>, ~place, ~placeId) => {
  let firestore = Firebase.useFirestore()
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)

  <section ariaLabelledby="kegs-setting" className={classes.root}>
    <header>
      <h3 id="kegs-setting"> {React.string("Sudy")} </h3>
      <button
        className={Styles.buttonClasses.button}
        onClick={_ => sendDialog(ShowAddKeg)}
        type_="button">
        {React.string("Přidat sud")}
      </button>
    </header>
    {switch kegs {
    | [] =>
      <div className={classes.emptyList}> {React.string("Naskladni sudy tlačítkem ⤴")} </div>
    | kegs =>
      <table>
        <thead>
          <th scope="col"> {React.string("No.")} </th>
          <th scope="col"> {React.string("Pivo")} </th>
          <th scope="col"> {React.string("Naskladněno")} </th>
          <th scope="col"> {React.string("Cena")} </th>
          <th scope="col"> {React.string("Objem")} </th>
          <th id="remaining_th" scope="col"> {React.string("Zbývá")} </th>
        </thead>
        <tbody>
          {kegs
          ->Array.map(keg => {
            let volume = keg.milliliters
            <tr key={keg.serial->Int.toString}>
              <th scope="row"> {React.string(`#${keg.serial->Int.toString}`)} </th>
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
                  value={volume->Int.toString}>
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
                milliliters: liters * 1000,
                priceNew: price,
                serial,
              },
            )
          )->ignore
          hideDialog()
        }}
        placeId
      />
    }}
  </section>
}
