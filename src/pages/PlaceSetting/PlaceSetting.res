type classesType = {root: string}

@module("./PlaceSettings.module.css") external classes: classesType = "default"

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let placeDocData = Db.usePlaceDocData(placeId)
  let (addTapDialogOpened, setAddTapDialogOpened) = React.useState(_ => false)
  let (basicDataDialogOpened, setBasicDataDialogOpened) = React.useState(_ => false)
  switch placeDocData.data {
  | Some(place) =>
    <div className={classes.root}>
      <PlaceHeader
        placeName={place.name}
        createdTimestamp={place.createdAt}
        slotRightButton={<button
          className={PlaceHeader.classes.iconButton}
          onClick={_ => setBasicDataDialogOpened(_ => true)}
          type_="button">
          <span> {React.string("✏️")} </span>
          <span> {React.string("Změnit")} </span>
        </button>}
      />
      <h3> {React.string("Pípy")} </h3>
      <button
        className={Styles.buttonClasses.button}
        onClick={_ => setAddTapDialogOpened(_ => true)}
        type_="button">
        {React.string("Přidat pípu")}
      </button>
      <ul>
        {place.taps
        ->Js.Dict.keys
        ->Array.map(tapName => {
          <li key={tapName}> {React.string(tapName)} </li>
        })
        ->React.array}
      </ul>
      {switch basicDataDialogOpened {
      | false => React.null
      | true =>
        let handleDismiss = _ => setBasicDataDialogOpened(_ => false)
        <BasicInfoDialog
          initialValues={{
            createdAt: place.createdAt->Firebase.Timestamp.toDate->DateUtils.toIsoDateString,
            name: place.name,
          }}
          onDismiss={handleDismiss}
          onSubmit={async values => {
            let placeDoc = Db.placeDocument(firestore, placeId)
            await Firebase.updateDoc(
              placeDoc,
              {
                ...place,
                createdAt: values.createdAt
                ->DateUtils.fromIsoDateString
                ->Firebase.Timestamp.fromDate,
                name: values.name,
              },
            )
            handleDismiss()
          }}
        />
      }}
      {switch addTapDialogOpened {
      | false => React.null
      | true => {
          let handleDismiss = _ => setAddTapDialogOpened(_ => false)
          <AddTapDialog
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
    </div>
  | _ => React.null
  }
}
