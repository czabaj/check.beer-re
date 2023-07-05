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
  let firestore = Firebase.useFirestore()
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  let hasKegsToTap = untappedChargedKegs->Array.length > 0
  let tappedKegsById = React.useMemo1(() =>
    tappedChargedKegs
    ->Belt.Array.keepMap(keg => {
      switch Db.getUid(keg) {
      | Some(uid) => Some((uid, keg))
      | None => None
      }
    })
    ->Belt.Map.String.fromArray
  , [tappedChargedKegs])

  <SectionWithHeader
    buttonsSlot={<button
      className={Styles.buttonClasses.button} onClick={_ => sendDialog(ShowAddTap)} type_="button">
      {React.string("Přidat pípu")}
    </button>}
    headerId="taps_setting"
    headerSlot={React.string("Pípy")}>
    <ul className={`reset ${classes.list}`}>
      {
        let tapsEntries = place.taps->Belt.Map.String.toArray
        let tapsCount = tapsEntries->Array.length
        tapsEntries
        ->Array.map(((tapName, maybeKegReference)) => {
          let tappedKeg =
            maybeKegReference
            ->Js.Null.toOption
            ->Option.flatMap(kegRef => tappedKegsById->Belt.Map.String.get(kegRef.id))

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
                className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
                onClick={_ => sendDialog(ShowTapKeg(tapName))}
                type_="button">
                {React.string("Narazit")}
              </button>
            | Some(keg) =>
              <button
                className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantDanger}`}
                onClick={_ => sendDialog(ShowUntapKeg(tapName, keg))}
                type_="button">
                {React.string("Odrazit")}
              </button>
            }}
            <button
              className={Styles.buttonClasses.button}
              onClick={_ => sendDialog(ShowRenameTap(tapName))}
              type_="button">
              {React.string("Přejmenovat")}
            </button>
            <button
              disabled={tappedKeg != None || tapsCount < 2}
              className={Styles.buttonClasses.button}
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
        existingNames={place.taps->Belt.Map.String.keysToArray}
        onDismiss={hideDialog}
        onSubmit={async values => {
          let newName = values.name
          await Db.updatePlace(
            firestore,
            placeId,
            {
              taps: place.taps->Belt.Map.String.set(newName, Js.null),
            },
          )
          hideDialog()
        }}
      />
    | DeleteTap(tapName) =>
      <ConfirmDeleteTap
        onConfirm={_ => {
          Db.updatePlace(firestore, placeId, {taps: place.taps->Belt.Map.String.remove(tapName)})
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
        existingNames={place.taps->Belt.Map.String.keysToArray}
        initialName=tapName
        onDismiss={hideDialog}
        onSubmit={async values => {
          let oldName = tapName
          let oldValue = place.taps->Belt.Map.String.getExn(oldName)
          let newName = values.name
          await Db.updatePlace(
            firestore,
            placeId,
            {
              personsAll: place.personsAll->Belt.Map.String.map(person => {
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
              }),
              taps: place.taps
              ->Belt.Map.String.remove(oldName)
              ->Belt.Map.String.set(newName, oldValue),
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
              taps: place.taps->Belt.Map.String.set(tapName, Some(kegDoc)->Js.Null.fromOption),
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
              await Db.updatePlace(
                firestore,
                placeId,
                {
                  taps: place.taps->Belt.Map.String.set(tapName, Null.null),
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
