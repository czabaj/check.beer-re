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
  | UntapKeg(string, Db.kegConverted)

type dialogEvent =
  | Hide
  | ShowAddTap
  | ShowDeleteTap(string)
  | ShowRenameTap(string)
  | ShowTapKeg(string)
  | ShowUntapKeg(string, Db.kegConverted)

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddTap => AddTap
  | ShowDeleteTap(tapName) => DeleteTap(tapName)
  | ShowRenameTap(tapName) => RenameTap(tapName)
  | ShowTapKeg(tapName) => TapKegOn(tapName)
  | ShowUntapKeg(tapName, keg) => UntapKeg(tapName, keg)
  }
}

@react.component
let make = (
  ~place: Db.placeConverted,
  ~placeId,
  ~tappedChargedKegs: array<Db.kegConverted>,
  ~untappedChargedKegs,
) => {
  let firestore = Reactfire.useFirestore()
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
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
      className={Styles.button.base} onClick={_ => sendDialog(ShowAddTap)} type_="button">
      {React.string("Přidat pípu")}
    </button>}
    headerId="taps_setting"
    headerSlot={React.string("Pípy")}>
    <ul className={`reset ${classes.list}`}>
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
              {tappedKeg->Option.mapWithDefault(React.null, keg => {
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
                className={`${Styles.button.base} ${Styles.button.variantPrimary}`}
                onClick={_ => sendDialog(ShowTapKeg(tapName))}
                type_="button">
                {React.string("Narazit")}
              </button>
            | Some(keg) =>
              <button
                className={`${Styles.button.base} ${Styles.button.variantDanger}`}
                onClick={_ => sendDialog(ShowUntapKeg(tapName, keg))}
                type_="button">
                {React.string("Odrazit")}
              </button>
            }}
            <button
              className={Styles.button.base}
              onClick={_ => sendDialog(ShowRenameTap(tapName))}
              type_="button">
              {React.string("Přejmenovat")}
            </button>
            <button
              disabled={tappedKeg != None || tapsCount < 2}
              className={Styles.button.base}
              onClick={_ => sendDialog(ShowDeleteTap(tapName))}
              type_="button">
              {React.string("Smazat")}
            </button>
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
          let newName = values.name
          let newTaps = ObjectUtils.setInD(place.taps, newName, Js.null)
          await Db.updatePlace(
            firestore,
            placeId,
            {
              taps: newTaps,
            },
          )
          hideDialog()
        }}
      />
    | DeleteTap(tapName) =>
      <ConfirmDeleteTap
        onConfirm={_ => {
          let updateData = ObjectUtils.setIn(
            Object.empty(),
            `taps.${tapName}`,
            Firebase.deleteField(),
          )
          Firebase.updateDoc(Db.placeDocument(firestore, placeId), updateData)
          ->Promise.then(_ => {
            hideDialog()
            Promise.resolve()
          })
          ->ignore
        }}
        onDismiss=hideDialog
        tapName
      />
    | RenameTap(tapName) =>
      <TapRename
        existingNames={place.taps->Js.Dict.keys}
        initialName=tapName
        onDismiss={hideDialog}
        onSubmit={async values => {
          let oldName = tapName
          let oldValue = place.taps->Js.Dict.unsafeGet(oldName)
          let newName = values.name
          let newTaps = place.taps->Dict.copy
          newTaps->Dict.delete(oldName)
          newTaps->Dict.set(newName, oldValue)
          await Db.updatePlace(
            firestore,
            placeId,
            {
              personsAll: place.personsAll->Js.Dict.map((. person: Db.personsAllRecord) => {
                switch person.preferredTap {
                | Some(preferredTap) =>
                  if preferredTap == oldName {
                    {
                      ...person,
                      preferredTap: Some(newName),
                    }
                  } else {
                    person
                  }
                | None => person
                }
              }, _),
              taps: newTaps,
            },
          )
          hideDialog()
        }}
      />
    | TapKegOn(tapName) =>
      <TapKegOn
        onDismiss={hideDialog}
        onSubmit={async values => {
          let kegDoc = Db.kegDoc(firestore, placeId, values.keg)
          await Db.updatePlace(
            firestore,
            placeId,
            {
              taps: ObjectUtils.setInD(place.taps, tapName, Null.make(kegDoc)),
            },
          )
          hideDialog()
        }}
        tapName
        untappedChargedKegs
      />
    | UntapKeg(tapName, keg) =>
      <TapKegOff
        onSubmit={async values => {
          switch values.untapOption {
          | "finish" => Js.Exn.raiseError("not implemented")
          | "toStocks" => {
              let newTaps = ObjectUtils.setInD(place.taps, tapName, Null.null)
              await Db.updatePlace(
                firestore,
                placeId,
                {
                  taps: newTaps,
                },
              )
              hideDialog()
            }
          | _ => Js.Exn.raiseError("unknown option")
          }
        }}
        onDismiss={hideDialog}
        keg
        tapName
      />
    }}
  </SectionWithHeader>
}
