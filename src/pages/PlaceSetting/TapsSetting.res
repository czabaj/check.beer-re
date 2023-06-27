type classesType = {root: string}

@module("./TapsSetting.module.css") external classes: classesType = "default"

@react.component
let make = (~place: FirestoreModels.place, ~placeId) => {
  let firestore = Firebase.useFirestore()
  let (addTapDialogOpened, setAddTapDialogOpened) = React.useState(_ => false)
  <section ariaLabelledby="kegs-setting" className={classes.root}>
    <header>
      <h3 id="kegs-setting"> {React.string("Pípy")} </h3>
      <button
        className={Styles.buttonClasses.button}
        onClick={_ => setAddTapDialogOpened(_ => true)}
        type_="button">
        {React.string("Přidat pípu")}
      </button>
    </header>
    <ul className="reset">
      {place.taps
      ->Js.Dict.keys
      ->Array.map(tapName => {
        <li key={tapName}>
          <span> {React.string(tapName)} </span>
          <button className={Styles.buttonClasses.button} type_="button">
            {React.string("Narazit")}
          </button>
          <button className={Styles.buttonClasses.button} type_="button">
            {React.string("Přejmenovat")}
          </button>
          <button className={Styles.buttonClasses.button} type_="button">
            {React.string("Smazat")}
          </button>
        </li>
      })
      ->React.array}
    </ul>
    {switch addTapDialogOpened {
    | false => React.null
    | true => {
        let handleDismiss = _ => setAddTapDialogOpened(_ => false)
        <AddTapDialog
          existingNames={place.taps->Js.Dict.keys}
          onDismiss={handleDismiss}
          onSubmit={async values => {
            switch place.taps->Js.Dict.get(values.name) {
            | Some(_) => Js.Exn.raiseError("Taková pípa už existuje")
            | None => {
                let placeDoc = Db.placeDocument(firestore, placeId)
                let newTaps = DictUtils.clone(place.taps)
                newTaps->Js.Dict.set(values.name, Js.Nullable.null)
                await Firebase.updateDoc(
                  placeDoc,
                  {
                    ...place,
                    taps: newTaps,
                  },
                )
                handleDismiss()
              }
            }
          }}
        />
      }
    }}
  </section>
}
