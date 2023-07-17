type dialogState = Hidden | AddPlace

let pageDataRx = (auth, firestore) => {
  open Rxjs
  let currentUserRx = Rxfire.user(auth)->pipe(keepMap(Null.toOption))
  let userPlacesRx =
    currentUserRx->pipe(
      switchMap((user: Firebase.User.t) => Db.placesByUserIdRx(firestore, user.uid)),
    )
  combineLatest2((currentUserRx, userPlacesRx))
}

@react.component
let make = () => {
  let firestore = Reactfire.useFirestore()
  let auth = Reactfire.useAuth()
  let (dialogState, setDialogState) = React.useState(() => Hidden)
  let hideDialog = _ => setDialogState(_ => Hidden)
  let pageDataStatus = Reactfire.useObservable(
    ~observableId="Page_MyPlaces",
    ~source=pageDataRx(auth, firestore),
  )

  {
    switch pageDataStatus.data {
    | Some((currentUser, userPlaces)) =>
      let userDisplayName = currentUser.displayName->Option.getExn
      <div className=Styles.page.narrow>
        <Header
          buttonLeftSlot={<button
            className={Header.classes.buttonLeft}
            onClick={_ => {
              auth->Firebase.Auth.signOut->ignore
              RescriptReactRouter.push("/")
            }}
            type_="button">
            <span> {React.string("🚴‍♂️")} </span>
            <span> {React.string("Odhlásit")} </span>
          </button>}
          buttonRightSlot={<a
            {...RouterUtils.createAnchorProps("./nastaveni")}
            className={Header.classes.buttonRight}>
            <span> {React.string("⚙️")} </span>
            <span> {React.string("Nastavení")} </span>
          </a>}
          headingSlot={React.string(userDisplayName)}
          subheadingSlot={React.null}
        />
        <main>
          <SectionWithHeader
            buttonsSlot={<button
              className={`${Styles.button.button} `}
              onClick={_ => setDialogState(_ => AddPlace)}
              type_="button">
              {React.string("Přidat místo")}
            </button>}
            headerId="my_places"
            headerSlot={React.string("Moje místa")}>
            {switch userPlaces {
            | [] => <p> {React.string("Nemáte žádná místa")} </p>
            | places =>
              <nav>
                <ul className={Styles.list.base}>
                  {places
                  ->Array.map(place => {
                    let stringId = Db.getUid(place)
                    <li key={stringId}>
                      <a
                        {...RouterUtils.createAnchorProps(`./${stringId}`)}
                        className={Styles.utility.breakout}>
                        {React.string(place.name)}
                      </a>
                    </li>
                  })
                  ->React.array}
                </ul>
              </nav>
            }}
          </SectionWithHeader>
        </main>
        {switch dialogState {
        | Hidden => React.null
        | AddPlace =>
          <PlaceAdd
            initialPersonName={userDisplayName}
            onDismiss={hideDialog}
            onSubmit={async values => {
              let placeDoc = Firebase.seedDoc(Db.placeCollection(firestore))
              let personDoc = Firebase.seedDoc(Db.placePersonsCollection(firestore, placeDoc.id))
              let defaultTapName = "Pípa"
              let now = Firebase.Timestamp.now()
              let personTuple = Db.personsAllRecordToTuple(. {
                balance: 0,
                name: values.personName,
                preferredTap: Some(defaultTapName),
                recentActivityAt: now,
              })
              await Firebase.writeBatch(firestore)
              ->Firebase.WriteBatch.set(
                placeDoc,
                {
                  createdAt: now,
                  currency: "CZK",
                  name: values.placeName,
                  personsAll: Dict.fromArray([(personDoc.id, personTuple)]),
                  taps: Dict.fromArray([(defaultTapName, Null.null)]),
                  users: Dict.fromArray([
                    (currentUser.uid, FirestoreModels.roleToJs(FirestoreModels.Owner)),
                  ]),
                },
                {},
              )
              ->Firebase.WriteBatch.set(
                personDoc,
                {
                  account: Js.Null.return(currentUser.uid),
                  createdAt: now,
                  name: values.personName,
                  transactions: [],
                },
                {},
              )
              ->Firebase.WriteBatch.commit
              hideDialog()
            }}
          />
        }}
      </div>
    | _ => React.null
    }
  }
}
