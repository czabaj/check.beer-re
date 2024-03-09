type classesType = {list: string, tappedBeer: string}
@module("./TapsSetting.module.css") external classes: classesType = "default"

module ConfirmDeleteTap = {
  @react.component
  let make = (~onConfirm, ~onDismiss, ~tapName) => {
    <DialogConfirmation heading="Smazat pípu ❓" onConfirm onDismiss visible=true>
      <div>
        {React.string("Potvzením smažete pípu: ")}
        <b> {React.string(tapName)} </b>
      </div>
    </DialogConfirmation>
  }
}

type dialogState =
  | Hidden
  | AddTap
  | RenameTap(string)
  | DeleteTap(string)
  | TapKegOn(string)

@react.component
let make = (
  ~place: FirestoreModels.place,
  ~placeId,
  ~tappedChargedKegs: array<Db.kegConverted>,
  ~untappedChargedKegs,
) => {
  let firestore = Reactfire.useFirestore()
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  let hasKegsToTap = untappedChargedKegs->Array.length > 0
  let tappedKegsById = React.useMemo1(
    () => tappedChargedKegs->Array.map(keg => (Db.getUid(keg), keg))->Dict.fromArray,
    [tappedChargedKegs],
  )
  let sortedTapEntries = React.useMemo1(() => {
    let tapsEntries = place.taps->Js.Dict.entries
    tapsEntries->Array.sort((a, b) => a->fst->String.localeCompare(b->fst))
    tapsEntries
  }, [place.taps])

  <SectionWithHeader
    buttonsSlot={<button
      className={Styles.button.base} onClick={_ => setDialog(_ => AddTap)} type_="button">
      {React.string("Přidat pípu")}
    </button>}
    headerId="taps_setting"
    headerSlot={React.string("Pípy")}>
    <ul className={classes.list}>
      {
        let tapsCount = sortedTapEntries->Array.length
        sortedTapEntries
        ->Array.map(((tapName, maybeKegReference)) => {
          let tappedKeg =
            maybeKegReference
            ->Js.Null.toOption
            ->Option.flatMap(kegRef => tappedKegsById->Dict.get(kegRef.id))

          <li key={tapName}>
            <div>
              {React.string(tapName)}
              {tappedKeg->Option.mapOr(React.null, keg => {
                <div className={classes.tappedBeer}>
                  <span> {React.string(keg.serialFormatted)} </span>
                  {React.string(HtmlEntities.nbsp)}
                  {React.string(keg.beer)}
                </div>
              })}
            </div>
            {switch tappedKeg {
            | None =>
              <button
                disabled={!hasKegsToTap}
                className={Styles.button.variantPrimary}
                onClick={_ => setDialog(_ => TapKegOn(tapName))}
                type_="button">
                {React.string("Narazit")}
              </button>
            | Some(_) =>
              <button
                className={Styles.button.variantDanger}
                onClick={_ => Db.Place.tapKegOff(firestore, ~placeId, ~tapName)->ignore}
                type_="button">
                {React.string("Odrazit")}
              </button>
            }}
            <ButtonMenu
              className={Styles.button.iconOnly}
              title="další akce"
              menuItems={[
                {
                  label: "Přejmenovat",
                  onClick: _ => setDialog(_ => RenameTap(tapName)),
                },
                {
                  disabled: tappedKeg != None || tapsCount < 2,
                  label: "Smazat",
                  onClick: _ => setDialog(_ => DeleteTap(tapName)),
                },
              ]}>
              {React.string("⋯")}
            </ButtonMenu>
          </li>
        })
        ->React.array
      }
    </ul>
    {switch dialogState {
    | Hidden => React.null
    | AddTap =>
      <TapAddNew
        existingNames={place.taps->Js.Dict.keys}
        onDismiss={hideDialog}
        onSubmit={async values => {
          Db.Place.tapAdd(firestore, ~placeId, ~tapName=values.name)->ignore
          hideDialog()
        }}
      />
    | DeleteTap(tapName) =>
      <ConfirmDeleteTap
        onConfirm={_ => {
          Db.Place.tapDelete(firestore, ~placeId, ~tapName)->ignore
        }}
        onDismiss=hideDialog
        tapName
      />
    | RenameTap(tapName) =>
      <TapRename
        existingNames={place.taps->Js.Dict.keys}
        initialName=tapName
        onDismiss={hideDialog}
        onSubmit={values => {
          Db.Place.tapRename(
            firestore,
            ~placeId,
            ~currentName=tapName,
            ~newName=values.name,
          )->ignore
          hideDialog()
        }}
      />
    | TapKegOn(tapName) =>
      <TapKegOn
        onDismiss={hideDialog}
        onSubmit={values => {
          Db.Place.tapKegOn(firestore, ~placeId, ~tapName, ~kegId=values.keg)->ignore
          hideDialog()
        }}
        tapName
        untappedChargedKegs
      />
    }}
  </SectionWithHeader>
}
