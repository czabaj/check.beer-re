let pageDataRx = (firestore, placeId) => {
  open Rxjs
  let placeRef = Db.placeDocument(firestore, placeId)
  let placeRx = Rxfire.docData(placeRef)->pipe(keepSome)
  let personsAllRx = Db.PersonsIndex.allEntriesSortedRx(firestore, ~placeId)
  let chargedKegsRx = Db.allChargedKegsRx(firestore, placeId)
  combineLatest3(placeRx, personsAllRx, chargedKegsRx)
}

type dialogState = Hidden | AddKeg | BasicInfoEdit | KegDetail(string)

@react.component
let make = (~placeId) => {
  let firestore = Reactfire.useFirestore()
  // this paginated call do not use suspense, call it above the placePageStatus which _is_ suspended
  let (maybeDepletedKegs, maybeFetchMoreDepletedKegs) = UsePaginatedDepletedKegsData.use(placeId)
  let pageDataStatus = Reactfire.useObservable(
    ~observableId=`Page_PlaceSetting_${placeId}`,
    ~source=pageDataRx(firestore, placeId),
  )
  let (dialogState, setDialog) = React.useState(() => Hidden)
  let hideDialog = _ => setDialog(_ => Hidden)
  switch pageDataStatus.data {
  | Some((place, personsAll, chargedKegs)) =>
    let kegsOnTapUids =
      place.taps
      ->Js.Dict.values
      ->Belt.Array.keepMap(maybeKegReference =>
        maybeKegReference->Js.Null.toOption->Option.map(ref => ref.id)
      )
    let (tappedChargedKegs, untappedChargedKegs) =
      chargedKegs->Belt.Array.partition(keg => kegsOnTapUids->Array.includes(Db.getUid(keg)))

    <FormattedCurrency.Provider value={place.currency}>
      <div className={Styles.page.narrow}>
        <PlaceHeader
          buttonRightSlot={<button
            className={Header.classes.buttonRight}
            onClick={_ => setDialog(_ => BasicInfoEdit)}
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
            personsCount={personsAll->Array.length}
            totalBalance={personsAll->Array.reduce(0, (sum, (_, person)) => sum + person.balance)}
          />
          <TapsSetting place placeId tappedChargedKegs untappedChargedKegs />
          <ChargedKegs
            chargedKegs
            onAddNewKeg={_ => setDialog(_ => AddKeg)}
            onKegDetail={kegId => setDialog(_ => KegDetail(kegId))}
          />
          <DepletedKegs maybeFetchMoreDepletedKegs maybeDepletedKegs />
        </main>
      </div>
      {switch dialogState {
      | Hidden => React.null
      | AddKeg =>
        <KegAddNew
          onDismiss={hideDialog}
          onSubmit={({beer, donors, milliliters, ownerIsDonor, price, serial}) => {
            let resolvedDonors = if !ownerIsDonor {
              donors
            } else {
              let userRole = FirestoreModels.roleToJs(FirestoreModels.Owner)
              let placeOwnerUid =
                place.users
                ->Dict.toArray
                ->Array.find(((_, role)) => role === userRole)
                ->Option.getExn
                ->fst
              let placeOwnerPersonId =
                personsAll
                ->Array.find(((_, person)) =>
                  switch person.userId->Null.toOption {
                  | Some(userId) => userId === placeOwnerUid
                  | _ => false
                  }
                )
                ->Option.getExn
                ->fst
              Js.Dict.fromArray([(placeOwnerPersonId, price)])
            }
            Firebase.addDoc(
              Db.placeKegsCollection(firestore, placeId),
              {
                beer,
                consumptions: Js.Dict.empty(),
                createdAt: Firebase.Timestamp.now(),
                donors: resolvedDonors,
                depletedAt: Null.null,
                milliliters,
                price,
                recentConsumptionAt: Null.null,
                serial,
              },
            )->ignore
            hideDialog()
          }}
          personsAll
          placeId
        />
      | BasicInfoEdit =>
        <BasicInfoDialog
          initialValues={{
            createdAt: place.createdAt->Firebase.Timestamp.toDate->DateUtils.toIsoDateString,
            name: place.name,
          }}
          onDismiss={hideDialog}
          onPlaceDelete={_ => {
            Db.Place.delete(firestore, ~placeId)->ignore
            RescriptReactRouter.replace("/misto")
          }}
          onSubmit={values => {
            Db.Place.update(
              firestore,
              ~placeId,
              ~createdAt=values.createdAt->DateUtils.fromIsoDateString->Firebase.Timestamp.fromDate,
              ~name=values.name,
            )->ignore
            hideDialog()
          }}
        />
      | KegDetail(kegId) => {
          let currentIdx = chargedKegs->Array.findIndex(keg => Db.getUid(keg) === kegId)
          let hasNext = currentIdx !== -1 && currentIdx < Array.length(chargedKegs) - 1
          let hasPrevious = currentIdx > 0
          let handleCycle = increase => {
            let allowed = increase ? hasNext : hasPrevious
            if allowed {
              let nextIdx = currentIdx + (increase ? 1 : -1)
              let nextKegId = chargedKegs->Belt.Array.getExn(nextIdx)->Db.getUid
              setDialog(_ => KegDetail(nextKegId))
            }
          }
          let keg = chargedKegs->Belt.Array.getExn(currentIdx)
          <KegDetail
            hasNext
            hasPrevious
            keg
            onDeleteConsumption={consumptionId => {
              Db.Keg.deleteConsumption(firestore, ~placeId, ~kegId, ~consumptionId)->ignore
            }}
            onDeleteKeg={_ => {
              Db.Keg.delete(firestore, ~placeId, ~kegId)->ignore
              hideDialog()
            }}
            onDismiss={hideDialog}
            onFinalizeKeg={() => {
              Db.Keg.finalize(firestore, placeId, kegId)->ignore
              hideDialog()
            }}
            onNextKeg={_ => handleCycle(true)}
            onPreviousKeg={_ => handleCycle(false)}
            personsAllById={personsAll->Js.Dict.fromArray}
            place
          />
        }
      }}
    </FormattedCurrency.Provider>
  | _ => React.null
  }
}
