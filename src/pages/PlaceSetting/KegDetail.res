type classesType = {actions: string, dialogCloseKeg: string, root: string}
@module("./KegDetail.module.css") external classes: classesType = "default"

type tableConsumptionsClassesType = {
  deleteButton: string,
  table: string,
}
@module("../../components/TableConsumptions/TableConsumptions.module.css")
external tableConsumptionsClasses: tableConsumptionsClassesType = "default"

type dialogState = Hidden | ConfirmDelete | ConfirmFinalize

@react.component
let make = (
  ~formatConsumption,
  ~hasNext,
  ~hasPrevious,
  ~isUserAuthorized,
  ~keg: Db.kegConverted,
  ~place: FirestoreModels.place,
  ~personsAllById: Dict.t<Db.personsAllRecord>,
  ~onDeleteConsumption,
  ~onDeleteKeg,
  ~onDismiss,
  ~onFinalizeKeg,
  ~onPreviousKeg,
  ~onNextKeg,
) => {
  let consumptionsByTimestampDesc = React.useMemo1(() => {
    let consumptionEntries = keg.consumptions->Js.Dict.entries
    consumptionEntries->Array.sort((a, b) => fst(b)->String.localeCompare(fst(a)))
    consumptionEntries
  }, [keg.consumptions])
  let firstConsumption = Db.kegFirstConsumptionTimestamp(keg)
  let priceLargeBeer =
    (keg.price->Int.toFloat /. keg.milliliters->Int.toFloat *. 500.0)->Int.fromFloat
  let effectivity = keg.consumptionsSum->Int.toFloat /. keg.milliliters->Int.toFloat
  let kegId = Db.getUid(keg)
  let kegName = `${keg.serialFormatted} ${keg.beer}`
  let maybeTapName =
    place.taps
    ->Js.Dict.entries
    ->Array.find(((_, maybeKegRef)) =>
      maybeKegRef
      ->Null.toOption
      ->Option.map(kegRef => kegRef.id === kegId)
      ->Option.getOr(false)
    )
    ->Option.map(((tapName, _)) => tapName)
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  <>
    <DialogCycling
      hasNext
      hasPrevious
      className=classes.root
      header={kegName}
      onDismiss
      onNext=onNextKeg
      onPrevious=onPreviousKeg
      visible=true>
      <dl className={Styles.descriptionList.inline}>
        <div>
          <dt> {React.string("objem")} </dt>
          <dd>
            <FormattedVolume milliliters={keg.milliliters} />
          </dd>
        </div>
        {keg.depletedAt !== Null.null || keg.consumptionsSum === 0
          ? React.null
          : <div>
              <dt> {React.string("zbýbá")} </dt>
              <dd>
                <FormattedVolume milliliters={keg.milliliters - keg.consumptionsSum} />
              </dd>
            </div>}
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
              <FormattedDateTime value={timestamp->Date.fromTime} />
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
                <FormattedVolume milliliters={keg.consumptionsSum} />
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
        <p className={Styles.messageBar.base}>
          {React.string(`Sud je naražen na pípu `)}
          <b> {React.string(tapName)} </b>
        </p>
      }}
      {keg.depletedAt !== Null.null ||
      !isUserAuthorized(UserRoles.Admin) ||
      consumptionsByTimestampDesc->Array.length === 0
        ? React.null
        : <div className={classes.actions}>
            <button
              className={Styles.button.variantDanger}
              disabled={consumptionsByTimestampDesc->Array.length === 0}
              onClick={_ => setDialog(_ => ConfirmFinalize)}
              type_="button">
              {React.string("Odepsat ze skladu a rozúčtovat")}
            </button>
          </div>}
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
                className={Styles.link.base}
                onClick={_ => setDialog(_ => ConfirmDelete)}
                type_="button">
                {React.string("odebrat z aplikace")}
              </button>
              {React.string(".")}
            </>
          }}
        </p>
      | _ =>
        <table className={`${Styles.table.inDialog} ${tableConsumptionsClasses.table}`}>
          <caption> {React.string("Vytočená piva")} </caption>
          <thead>
            <tr>
              <th scope="col"> {React.string("Jméno")} </th>
              <th scope="col"> {React.string("Kdy")} </th>
              <th scope="col"> {React.string("Objem")} </th>
              <th scope="col">
                <span className={Styles.utility.srOnly}> {React.string("Akce")} </span>
              </th>
            </tr>
          </thead>
          <tbody>
            {consumptionsByTimestampDesc
            ->Array.map(((timestampStr, consumption)) => {
              let person = personsAllById->Dict.getUnsafe(consumption.person.id)
              let createdData = timestampStr->Float.fromString->Option.getExn->Date.fromTime
              <tr key={timestampStr}>
                <th scope="row"> {React.string(person.name)} </th>
                <td>
                  <FormattedDateTimeShort value={createdData} />
                </td>
                <td> {formatConsumption(consumption.milliliters)->React.string} </td>
                <td>
                  {keg.depletedAt !== Null.null
                    ? React.null
                    : <button
                        className={`${Styles.button.sizeExtraSmall} ${tableConsumptionsClasses.deleteButton}`}
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
      }}
    </DialogCycling>
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
        className={`${DialogConfirmation.classes.deleteConfirmation} ${classes.dialogCloseKeg}`}
        heading="Chystáte se rozúčtovat sud"
        onConfirm={() => {
          onDismiss()
          onFinalizeKeg()
        }}
        onDismiss={() => hideDialog()}
        visible=true>
        <dl className={Styles.descriptionList.hyphen}>
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
        {effectivity > 0.7
          ? <p className=Styles.messageBar.base role="alert">
              {React.string(`Rozúčtování je nevratná operace. Ujistěte se, že máte správny sud.`)}
            </p>
          : <p className={Styles.messageBar.variantDanger} role="alert">
              <b> {React.string(`Efektivita výtoče je velmi nízká.`)} </b>
              {React.string(` Rozúčtování je nevratná operace. Ujistěte se, že máte správny sud.`)}
            </p>}
      </DialogConfirmation>
    }}
  </>
}
