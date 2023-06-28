type classesType = {list: string}
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
  Hidden | AddTap | RenameTap(string) | DeleteTap(string) | TapKegOn(string) | UntapKeg(string)

type dialogEvent =
  | Hide
  | ShowAddTap
  | ShowDeleteTap(string)
  | ShowRenameTap(string)
  | ShowTapKeg(string)
  | ShowUntapKeg(string)

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddTap => AddTap
  | ShowDeleteTap(tapName) => DeleteTap(tapName)
  | ShowRenameTap(tapName) => RenameTap(tapName)
  | ShowTapKeg(tapName) => TapKegOn(tapName)
  | ShowUntapKeg(tapName) => UntapKeg(tapName)
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
  let placeDoc = Db.placeDocumentConverted(firestore, placeId)
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  let hasKegsToTap = untappedChargedKegs->Array.length > 0

  <SectionWithHeader
    buttonsSlot={<button
      className={Styles.buttonClasses.button} onClick={_ => sendDialog(ShowAddTap)} type_="button">
      {React.string("Přidat pípu")}
    </button>}
    headerId="taps-setting"
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
            ->Option.map(kegRef =>
              tappedChargedKegs
              ->Array.find(
                keg =>
                  switch Db.getUid(keg) {
                  | Some(uid) => uid === kegRef.id
                  | _ => false
                  },
              )
              ->Option.getUnsafe
            )
          <li key={tapName}>
            <div>
              {React.string(tapName)}
              {tappedKeg->Option.mapWithDefault(React.null, keg => {
                <span> {React.string(` 🍺 ${keg.beer}`)} </span>
              })}
            </div>
            {tappedKeg === None
              ? <button
                  disabled={!hasKegsToTap}
                  className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
                  onClick={_ => sendDialog(ShowTapKeg(tapName))}
                  type_="button">
                  {React.string("Narazit")}
                </button>
              : <button
                  className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
                  type_="button">
                  {React.string("Odrazit")}
                </button>}
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
          await Firebase.setDoc(
            placeDoc,
            {
              ...place,
              taps: place.taps->Belt.Map.String.set(newName, Js.null),
            },
          )
          hideDialog()
        }}
      />
    | DeleteTap(tapName) =>
      <ConfirmDeleteTap
        onConfirm={_ => {
          Firebase.setDoc(
            placeDoc,
            {
              ...place,
              taps: place.taps->Belt.Map.String.remove(tapName),
            },
          )
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
          await Firebase.setDoc(
            placeDoc,
            {
              ...place,
              personsAll: place.personsAll->Belt.Map.String.map(person => {
                switch person {
                | (a, b, Some(c)) =>
                  if c === oldName {
                    (a, b, Some(newName))
                  } else {
                    person
                  }
                | _ => person
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
          let tapsDict =
            place.taps
            ->Belt.Map.String.set(tapName, Some(kegDoc)->Js.Null.fromOption)
            ->Belt.Map.String.toArray
            ->Js.Dict.fromArray
          %debugger
          await Firebase.updateDoc(
            placeDoc,
            {
              "taps": tapsDict,
            },
          )
          ()
        }}
        tapName
        untappedChargedKegs
      />
    | UntapKeg(tapName) => React.null
    }}
  </SectionWithHeader>
}
