type classesType = {root: string}

@module("./SettingSection.module.css") external classes: classesType = "default"

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

type dialogState = Hidden | AddTap | RenameTap(string) | DeleteTap(string)

type dialogEvent = Hide | ShowAddTap | ShowRenameTap(string) | ShowDeleteTap(string)

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddTap => AddTap
  | ShowRenameTap(tapName) => RenameTap(tapName)
  | ShowDeleteTap(tapName) => DeleteTap(tapName)
  }
}

@react.component
let make = (~place: Db.placeConverted, ~placeId) => {
  let firestore = Firebase.useFirestore()
  let placeDoc = Db.placeDocumentConverted(firestore, placeId)
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  <section ariaLabelledby="taps-setting" className={classes.root}>
    <header>
      <h3 id="taps-setting"> {React.string("Pípy")} </h3>
      <button
        className={Styles.buttonClasses.button}
        onClick={_ => sendDialog(ShowAddTap)}
        type_="button">
        {React.string("Přidat pípu")}
      </button>
    </header>
    <ul className="reset">
      {
        let tapsEntries = place.taps->Belt.Map.String.toArray
        let tapsCount = tapsEntries->Array.length
        tapsEntries
        ->Array.map(((tapName, maybeKegReference)) => {
          let hasKeg = maybeKegReference->Js.Nullable.toOption->Js.Option.isSome
          <li key={tapName}>
            <span> {React.string(tapName)} </span>
            {switch hasKeg {
            | false =>
              <button
                className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
                type_="button">
                {React.string("Narazit")}
              </button>
            | true =>
              <button
                className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
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
              disabled={hasKeg || tapsCount < 2}
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
          let noKeg = Js.Nullable.null
          await Firebase.setDoc(
            placeDoc,
            {
              ...place,
              taps: place.taps->Belt.Map.String.set(newName, noKeg),
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
    }}
  </section>
}
