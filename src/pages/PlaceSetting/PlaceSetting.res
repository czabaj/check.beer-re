type classesType = {root: string}

@module("./PlaceSettings.module.css") external classes: classesType = "default"

let pageDataRx = (firestore, placeId) => {
  let placeRef = Db.placeDocumentConverted(firestore, placeId)
  let placeRx = Firebase.docDataRx(placeRef, Db.reactFireOptions)
  let chargedKegsQuery = Firebase.query(
    Db.placeKegsCollectionConverted(firestore, placeId),
    [
      Firebase.where("depletedAt", #"==", null),
      // limit to 50 to avoid expensive calls, but 50 kegs on stock is a lot
      Firebase.limit(50),
    ],
  )
  let chargedKegsRx = Firebase.collectionDataRx(chargedKegsQuery, Db.reactFireOptions)
  Rxjs.combineLatest2((placeRx, chargedKegsRx))
}

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  let placePageStatus = Firebase.useObservable(
    ~observableId="PlaceSettingPage",
    ~source=pageDataRx(firestore, placeId),
  )
  let (basicDataDialogOpened, setBasicDataDialogOpened) = React.useState(_ => false)
  switch placePageStatus.data {
  | Some((place, chargedKegs)) =>
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
          <AccountingOverview chargedKegs untappedChargedKegs />
          <ChargedKegsSetting chargedKegs place placeId />
          <DepletedKegs placeId />
        </main>
      </div>
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
