type classesType = {footer: string, list: string}

@module("./MyPlaces.module.css") external classes: classesType = "default"

type dialogState = Hidden | AddPlace | EditUser

let gitShortSha: string = %raw(`import.meta.env.VITE_GIT_SHORT_SHA`)

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
    let sinceDate = currentUser.metadata.creationTime->Date.fromString
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
        subheadingSlot={<ReactIntl.FormattedMessage
          id="Place.established"
          defaultMessage={"Již od {time}"}
          values={{
            "time": <time dateTime={sinceDate->Date.toISOString}>
              <ReactIntl.FormattedDate value={sinceDate} />
            </time>,
          }}
        />}
      />
      <main>
        <SectionWithHeader
          buttonsSlot={<button
            className={Styles.button.base} onClick={_ => onPlaceAdd()} type_="button">
            {React.string("Nové místo")}
          </button>}
          headerId="my_places"
          headerSlot={React.string("Moje místa")}
          noBackground={true}>
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
              <ul className={classes.list}>
                {places
                ->Array.map(place => {
                  let stringId = Db.getUid(place)
                  <li key={stringId}>
                    <a
                      {...RouterUtils.createAnchorProps(`./${stringId}`)}
                      className={Styles.utility.breakout}>
                      {React.string(place.name)}
                    </a>
                    <span>
                      {React.string("Založeno: ")}
                      <ReactIntl.FormattedDate
                        day=#numeric
                        month=#numeric
                        year=#numeric
                        value={place.createdAt->Firebase.Timestamp.toDate}
                      />
                    </span>
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
  let currentUserRx = Rxfire.user(auth)->op(keepMap(Null.toOption))
  let userPlacesRx =
    currentUserRx->op(
      switchMap((user: Firebase.User.t) => Db.placesByUserIdRx(firestore, user.uid)),
    )
  combineLatest2(currentUserRx, userPlacesRx)
}

@react.component
let make = () => {
  LogUtils.usePageView("MyPlaces")
  let firestore = Reactfire.useFirestore()
  let auth = Reactfire.useAuth()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId="Page_MyPlaces",
    ~source=pageDataRx(auth, firestore),
  )
  let (dialogState, setDialogState) = React.useState(() => Hidden)
  let hideDialog = _ => setDialogState(_ => Hidden)
  let fromHomepage = RescriptReactRouter.useUrl()->RouterUtils.isFromHomepage
  <>
    {switch (fromHomepage, pageDataStatus.data) {
    | (true, Some(_, [onePlaceOnly])) =>
      let singlePlaceLocation = RouterUtils.resolveRelativePath(`./${Db.getUid(onePlaceOnly)}`)
      <Redirect to=singlePlaceLocation />
    | (_, Some(currentUser, usersPlaces)) =>
      let userDisplayName = currentUser.displayName->Null.getExn
      <>
        <Pure
          currentUser
          onPlaceAdd={() => setDialogState(_ => AddPlace)}
          onSignOut={() => {
            RescriptReactRouter.push("/")
            auth->Firebase.Auth.signOut->ignore
            Js.Global.setTimeout(() => {
              // reload the page for clearing Reactfire observables cache
              // @see https://github.com/FirebaseExtended/reactfire/issues/485#issuecomment-1028575121
              location->Location.reload
            }, 0)->ignore
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
            connectedEmail={currentUser.email->Null.getExn}
            initialName={userDisplayName}
            onChangePassword={async values => {
              let credential = Firebase.Auth.EmailAuthProvider.credential(
                ~email=currentUser.email->Null.getExn,
                ~password=values.oldPassword,
              )
              let _ = await Firebase.Auth.reauthenticateWithCredential(currentUser, credential)
              let _ = await Firebase.Auth.updatePassword(
                currentUser,
                ~newPassword=values.newPassword,
              )
            }}
            onDismiss={hideDialog}
            onSubmit={async values => {
              let _ = await Firebase.Auth.updateProfile(currentUser, {displayName: values.name})
              hideDialog()
            }}
          />
        }}
      </>
    | _ => React.null
    }}
    <footer className={classes.footer}> {React.string("v.\xA0" ++ gitShortSha)} </footer>
  </>
}
