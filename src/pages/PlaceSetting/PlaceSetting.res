type classesType = {root: string}

@module("./PlaceSettings.module.css") external classes: classesType = "default"

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let placeDocData = Db.usePlaceDocData(placeId)
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
      <TapsSetting place placeId />
    </div>
  | _ => React.null
  }
}
