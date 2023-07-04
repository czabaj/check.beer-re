type classesType = {root: string}

@module("./PlaceSettings.module.css") external classes: classesType = "default"

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let placeDocData = Db.usePlaceDocData(placeId)
  let chargedKegsStatus = Db.useChargedKegsStatus(placeId)
  let (basicDataDialogOpened, setBasicDataDialogOpened) = React.useState(_ => false)
  switch (placeDocData.data, chargedKegsStatus.data) {
  | (Some(place), Some(chargedKegs)) =>
    let kegsOnTapUids =
      place.taps
      ->Belt.Map.String.valuesToArray
      ->Belt.Array.keepMap(maybeKegReference =>
        maybeKegReference->Js.Null.toOption->Option.map(ref => ref.id)
      )
    let (untappedChargedKegs, tappedChargedKegs) = chargedKegs->Belt.Array.partition(keg => {
      switch Db.getUid(keg) {
      | Some(kegUid) => !(kegsOnTapUids->Array.includes(kegUid))
      | None => false
      }
    })

    <FormattedCurrency.Provider value={place.currency}>
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
        <main>
          {!basicDataDialogOpened
            ? React.null
            : {
                let handleDismiss = _ => setBasicDataDialogOpened(_ => false)
                <BasicInfoDialog
                  initialValues={{
                    createdAt: place.createdAt
                    ->Firebase.Timestamp.toDate
                    ->DateUtils.toIsoDateString,
                    name: place.name,
                  }}
                  onDismiss={handleDismiss}
                  onSubmit={async values => {
                    let placeDoc = Db.placeDocumentConverted(firestore, placeId)
                    await Firebase.setDoc(
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
          <TapsSetting place placeId tappedChargedKegs untappedChargedKegs />
          <KegsSetting chargedKegs place placeId />
          <AccountingOverview chargedKegs untappedChargedKegs />
        </main>
      </div>
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
