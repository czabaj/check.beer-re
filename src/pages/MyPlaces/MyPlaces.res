type dialogState = Hidden | AddPlace | EditUser

module Pure = {
  @genType @react.component
  let make = (
    ~currentUser: Firebase.User.t,
    ~onPlaceAdd,
    ~onSignOut,
    ~onSettingsClick,
    ~usersPlaces: array<FirestoreModels.place>,
  ) => {
    let userDisplayName = currentUser.displayName->Null.getExn
    <div className=Styles.page.narrow>
      <Header
        buttonLeftSlot={<button
          className={Header.classes.buttonLeft} onClick={_ => onSignOut()} type_="button">
          <span> {React.string("🚴‍♂️")} </span>
          <span> {React.string("Odhlásit")} </span>
        </button>}
        buttonRightSlot={<button
          className={Header.classes.buttonRight} onClick={onSettingsClick} type_="button">
          <span> {React.string("⚙️")} </span>
          <span> {React.string("Nastavení")} </span>
        </button>}
        headingSlot={React.string(userDisplayName)}
        subheadingSlot={React.null}
      />
      <main>
        <SectionWithHeader
          buttonsSlot={<button
            className={`${Styles.button.base} `} onClick={_ => onPlaceAdd()} type_="button">
            {React.string("Nové místo")}
          </button>}
          headerId="my_places"
          headerSlot={React.string("Moje místa")}>
          {switch usersPlaces {
          | [] =>
            <p className=SectionWithHeader.classes.emptyMessage>
              {React.string(
                "Seznam vašich míst je prázdný, nechte se někam pozvat 🍻 nebo ",
              )}
              <button className={Styles.link.base} onClick={_ => onPlaceAdd()} type_="button">
                {React.string("založte nové místo pro vaše přátele.")}
              </button>
            </p>
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
    </div>
  }
}

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
  let pageDataStatus = Reactfire.useObservable(
    ~observableId="Page_MyPlaces",
    ~source=pageDataRx(auth, firestore),
  )
  let (dialogState, setDialogState) = React.useState(() => Hidden)
  let hideDialog = _ => setDialogState(_ => Hidden)

  {
    switch pageDataStatus.data {
    | Some((currentUser, usersPlaces)) =>
      let userDisplayName = currentUser.displayName->Null.getExn
      <>
        <Pure
          currentUser
          onPlaceAdd={() => setDialogState(_ => AddPlace)}
          onSignOut={() => {
            auth->Firebase.Auth.signOut->ignore
            RescriptReactRouter.push("/")
          }}
          onSettingsClick={_ => setDialogState(_ => EditUser)}
          usersPlaces
        />
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
      </>
    | _ => React.null
    }
  }
}
