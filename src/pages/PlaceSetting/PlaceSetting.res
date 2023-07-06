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

type dialogState = Hidden | AddKeg | BasicInfoEdit | KegDetail(string)

type dialogEvent = Hide | ShowAddKeg | ShowBasicInfoEdit | ShowKegDetail(string)

let dialogReducer = (_, event) => {
  switch event {
  | Hide => Hidden
  | ShowAddKeg => AddKeg
  | ShowBasicInfoEdit => BasicInfoEdit
  | ShowKegDetail(kegId) => KegDetail(kegId)
  }
}

@react.component
let make = (~placeId) => {
  let firestore = Firebase.useFirestore()
  // this paginated call do not use suspense, call it above the placePageStatus which _is_ suspended
  let (maybeDepletedKegs, maybeFetchMoreDepletedKegs) = UsePaginatedDepletedKegsData.use(placeId)
  let placePageStatus = Firebase.useObservable(
    ~observableId="PlaceSettingPage",
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
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
            onClick={_ => sendDialog(ShowBasicInfoEdit)}
            type_="button">
            <span> {React.string("✏️")} </span>
            <span> {React.string("Změnit")} </span>
          </button>}
        />
        <main>
          <AccountingOverview chargedKegs untappedChargedKegs />
          <TapsSetting place placeId tappedChargedKegs untappedChargedKegs />
          <ChargedKegs
            chargedKegs
            onAddNewKeg={_ => sendDialog(ShowAddKeg)}
            onKegDetail={kegId => sendDialog(ShowKegDetail(kegId))}
          />
          <DepletedKegs maybeFetchMoreDepletedKegs maybeDepletedKegs />
        </main>
      </div>
      {switch dialogState {
      | Hidden => React.null
      | AddKeg =>
        <KegAddNew
          onDismiss={hideDialog}
          onSubmit={async ({beer, liters, price, serial}) => {
            let minorUnit = FormattedCurrency.getMinorUnit(place.currency)
            let _ = await Firebase.addDoc(
              Db.placeKegsCollection(firestore, placeId),
              {
                beer,
                consumptions: Js.Dict.empty(),
                createdAt: Firebase.Timestamp.now(),
                depletedAt: Null.null,
                milliliters: (liters *. 1000.0)->Int.fromFloat,
                price: (price *. minorUnit)->Int.fromFloat,
                recentConsumptionAt: Null.null,
                serial,
              },
            )
            hideDialog()
          }}
          placeId
        />
      | BasicInfoEdit =>
        <BasicInfoDialog
          initialValues={{
            createdAt: place.createdAt->Firebase.Timestamp.toDate->DateUtils.toIsoDateString,
            name: place.name,
          }}
          onDismiss={hideDialog}
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
            hideDialog()
          }}
        />
      | KegDetail(kegId) => {
          let currentIdx =
            chargedKegs->Array.findIndex(keg => Db.getUid(keg)->Option.getExn === kegId)
          let hasNext = currentIdx !== -1 && currentIdx < Array.length(chargedKegs) - 1
          let hasPrevious = currentIdx > 0
          let handleCycle = increase => {
            let allowed = increase ? hasNext : hasPrevious
            if allowed {
              let nextIdx = currentIdx + (increase ? 1 : -1)
              let nextKegId = chargedKegs->Belt.Array.getExn(nextIdx)->Db.getUid->Option.getExn
              sendDialog(ShowKegDetail(nextKegId))
            }
          }
          let keg = chargedKegs->Belt.Array.getExn(currentIdx)
          <KegDetail
            hasNext
            hasPrevious
            keg
            onDeleteConsumption={consumptionId => {
              Db.deleteConsumption(firestore, placeId, kegId, consumptionId)->ignore
            }}
            onDeleteKeg={_ => {
              Db.deleteKeg(firestore, placeId, kegId)->ignore
              hideDialog()
            }}
            onDismiss={hideDialog}
            onFinalizeKeg={() => {
              Db.finalizeKeg(firestore, placeId, kegId)->ignore
              hideDialog()
            }}
            onNextKeg={_ => handleCycle(true)}
            onPreviousKeg={_ => handleCycle(false)}
            place
          />
        }
      }}
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
