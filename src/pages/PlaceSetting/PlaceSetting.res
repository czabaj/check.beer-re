let pageDataRx = (firestore, placeId) => {
  let placeRef = Db.placeDocumentConverted(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)
  let chargedKegsRx = Db.allChargedKegsRx(firestore, placeId)
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
  let firestore = Reactfire.useFirestore()
  // this paginated call do not use suspense, call it above the placePageStatus which _is_ suspended
  let (maybeDepletedKegs, maybeFetchMoreDepletedKegs) = UsePaginatedDepletedKegsData.use(placeId)
  let pageDataStatus = Reactfire.useObservable(
    ~observableId="PlaceSettingPage",
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, sendDialog) = React.useReducer(dialogReducer, Hidden)
  let hideDialog = _ => sendDialog(Hide)
  switch pageDataStatus.data {
  | Some((place, chargedKegs)) =>
    let kegsOnTapUids =
      place.taps
      ->Js.Dict.values
      ->Belt.Array.keepMap(maybeKegReference =>
        maybeKegReference->Js.Null.toOption->Option.map(ref => ref.id)
      )
    let (untappedChargedKegs, tappedChargedKegs) = chargedKegs->Belt.Array.partition(keg => {
      switch Db.getUid(keg) {
      | Some(kegUid) => !(kegsOnTapUids->Array.includes(kegUid))
      | None => false
      }
    })
    let personsAllEntries = place.personsAll->Js.Dict.entries

    <FormattedCurrency.Provider value={place.currency}>
      <div className={Styles.page.narrow}>
        <PlaceHeader
          buttonRightSlot={<button
            className={Header.classes.buttonRight}
            onClick={_ => sendDialog(ShowBasicInfoEdit)}
            type_="button">
            <span> {React.string("✏️")} </span>
            <span> {React.string("Změnit")} </span>
          </button>}
          createdTimestamp={place.createdAt}
          placeName={place.name}
        />
        <main>
          <PlaceStats
            chargedKegsValue={chargedKegs->Array.reduce(0, (sum, keg) => sum + keg.price)}
            personsCount={personsAllEntries->Array.length}
            totalBalance={personsAllEntries->Array.reduce(0, (sum, (_, person)) =>
              sum + person.balance
            )}
          />
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
          onSubmit={async ({beer, donors, milliliters, price, serial}) => {
            let _ = await Firebase.addDoc(
              Db.placeKegsCollection(firestore, placeId),
              {
                beer,
                consumptions: Js.Dict.empty(),
                createdAt: Firebase.Timestamp.now(),
                donors,
                depletedAt: Null.null,
                milliliters,
                price,
                recentConsumptionAt: Null.null,
                serial,
              },
            )
            hideDialog()
          }}
          place
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
