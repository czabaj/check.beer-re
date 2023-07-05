type classesType = {root: string}
@module("./KegDetail.module.css") external classes: classesType = "default"

type dialogState = Hidden | ConfirmDelete | ConfirmFinalize

type dialogEvent = Hide | ShowConfirmDelete | ShowConfirmFinalize

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowConfirmDelete => ConfirmDelete
  | ShowConfirmFinalize => ConfirmFinalize
  }
}

@react.component
let make = (
  ~hasNext,
  ~hasPrevious,
  ~keg: Db.kegConverted,
  ~place: Db.placeConverted,
  ~onDeleteConsumption,
  ~onDeleteKeg,
  ~onDismiss,
  ~onFinalizeKeg,
  ~onPreviousKeg,
  ~onNextKeg,
) => {
  let consumptionsByTimestampDesc = React.useMemo1(() =>
    keg.consumptions
    ->Belt.Map.String.toArray
    // The map is sorted by timestamp ascending, we want descending
    ->Array.reverse
  , [keg.consumptions])
  let firstConsumption =
    consumptionsByTimestampDesc
    ->Array.get(consumptionsByTimestampDesc->Array.length - 1)
    ->Option.flatMap(((timestampStr, _)) => timestampStr->Float.fromString)
  let priceLargeBeer =
    (keg.price->Int.toFloat /. keg.milliliters->Int.toFloat *. 500.0)->Int.fromFloat
  let effectivity = keg.consumptionsSum->Int.toFloat /. keg.milliliters->Int.toFloat
  let kegId = Db.getUid(keg)->Option.getExn
  let kegName = `${keg.serialFormatted} ${keg.beer}`
  let maybeTapName =
    place.taps
    ->Belt.Map.String.findFirstBy((_, maybeKegRef) =>
      maybeKegRef
      ->Null.toOption
      ->Option.map(kegRef => kegRef.id === kegId)
      ->Option.getWithDefault(false)
    )
    ->Option.map(((tapName, _)) => tapName)
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  <DialogCycling
    hasNext
    hasPrevious
    className=classes.root
    header={kegName}
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
          <dt> {React.string("první výtoč")} </dt>
          <dd>
            <FormattedDateTime value={timestamp->Js.Date.fromFloat} />
          </dd>
        </div>
      }}
      {switch keg.depletedAt->Null.toOption {
      | None => React.null
      | Some(depletedAt) =>
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
            <dd>
              <FormattedPercent value={effectivity *. 100.0} />
            </dd>
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
      }}
    </dl>
    {switch maybeTapName {
    | None => React.null
    | Some(tapName) =>
      <p className={Styles.messageBarClasses.info}>
        {React.string(`Sud je naražen na pípu ${tapName}`)}
      </p>
    }}
    {switch consumptionsByTimestampDesc {
    | [] =>
      <p>
        {React.string("Ze sudu zatím neevidujeme čepování.")}
        {switch maybeTapName {
        | Some(_) => React.null
        | None =>
          <>
            {React.string(" Pokud jste sud přidali omylem můžete ho ")}
            <button
              className={Styles.linkClasses.base}
              onClick={_ => sendDialog(ShowConfirmDelete)}
              type_="button">
              {React.string("odebrat z aplikace")}
            </button>
            {React.string(".")}
          </>
        }}
      </p>
    | _ =>
      <>
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
              <tr key={timestampStr}>
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
        {keg.depletedAt !== Null.null
          ? React.null
          : <button
              className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantDanger}`}
              onClick={_ => sendDialog(ShowConfirmFinalize)}
              type_="button">
              {React.string("Odepsat ze skladu a rozúčtovat")}
            </button>}
      </>
    }}
    {switch dialogState {
    | Hidden => React.null
    | ConfirmDelete =>
      <DialogConfirmation
        className={DialogConfirmation.classes.deleteConfirmation}
        heading="Odstranit sud ?"
        onConfirm={() => {
          onDismiss()
          onDeleteKeg()
        }}
        onDismiss={() => hideDialog()}
        visible=true>
        <p>
          {React.string(`Chystáte se odstranit sud `)}
          <b> {React.string(kegName)} </b>
          {React.string(` z aplikace. Chcete pokračovat?`)}
        </p>
      </DialogConfirmation>
    | ConfirmFinalize =>
      <DialogConfirmation
        className={DialogConfirmation.classes.deleteConfirmation}
        heading="Chystáte se rozúčtovat sud"
        onConfirm={() => {
          onDismiss()
          onFinalizeKeg()
        }}
        onDismiss={() => hideDialog()}
        visible=true>
        <dl>
          <dt> {React.string("Název sudu")} </dt>
          <dd> {React.string(kegName)} </dd>
          <dt> {React.string("Celkem vytočeno")} </dt>
          <dd>
            <FormattedVolume milliliters=keg.consumptionsSum />
            {React.string(" z ")}
            <FormattedVolume milliliters=keg.milliliters />
            {React.string(" (efektivita ")}
            <FormattedPercent value={effectivity *. 100.0} />
            {React.string(")")}
          </dd>
          <dt> {React.string(`Výsledná cena velkého piva${HtmlEntities.nbsp}*`)} </dt>
          <dd>
            <FormattedCurrency
              value={(priceLargeBeer->Int.toFloat /. effectivity)->Int.fromFloat}
            />
          </dd>
        </dl>
        <p>
          {React.string(`* Mezi konzumenty se rozpočítává cena sudu, výslednou cenu velkého piva tak ovlivňuje
          efektivita výtoče.`)}
        </p>
      </DialogConfirmation>
    }}
  </DialogCycling>
}
