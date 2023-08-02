type classesType = {empty: string}

@module("./MyPlaces.module.css") external classes: classesType = "default"

type dialogState = Hidden | AddPlace | EditUser

let pageDataRx = (auth, firestore) => {
  open Rxjs
  let currentUserRx = Rxfire.user(auth)->pipe(keepMap(Null.toOption))
  let userPlacesRx =
    currentUserRx->pipe(
      switchMap((user: Firebase.User.t) => Db.placesByUserIdRx(firestore, user.uid)),
    )
  combineLatest2(currentUserRx, userPlacesRx)
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
      let userDisplayName = currentUser.displayName->Null.getExn
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
          buttonRightSlot={<button
            className={Header.classes.buttonRight}
            onClick={_ => setDialogState(_ => EditUser)}
            type_="button">
            <span> {React.string("⚙️")} </span>
            <span> {React.string("Nastavení")} </span>
          </button>}
          headingSlot={React.string(userDisplayName)}
          subheadingSlot={React.null}
        />
        <main>
          <SectionWithHeader
            buttonsSlot={<button
              className={`${Styles.button.base} `}
              onClick={_ => setDialogState(_ => AddPlace)}
              type_="button">
              {React.string("Přidat místo")}
            </button>}
            headerId="my_places"
            headerSlot={React.string("Moje místa")}>
            {switch userPlaces {
            | [] => <p className=classes.empty> {React.string("Nemáte žádná místa")} </p>
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
            onSubmit={async ({personName, placeName}) => {
              let placeRef = await Db.Place.add(
                firestore,
                ~personName,
                ~placeName,
                ~userId=currentUser.uid,
              )
              RescriptReactRouter.push(RouterUtils.resolveRelativePath(`./${placeRef.id}`))
            }}
          />
        | EditUser =>
          <EditUser
            initialName={userDisplayName}
            onDismiss={hideDialog}
            onSubmit={async values => {
              let _ = await Firebase.Auth.updateProfile(currentUser, {displayName: values.name})
              hideDialog()
            }}
          />
        }}
      </div>
    | _ => React.null
    }
  }
}
