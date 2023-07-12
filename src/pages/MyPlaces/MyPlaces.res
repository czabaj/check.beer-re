type dialogState = Hidden | AddPlace

@react.component
let make = () => {
  let firestore = Firebase.useFirestore()
  let currentUserAccountDoc = Db.useCurrentUserAccountDocData()
  let auth = Firebase.useAuth()
  let (dialogState, setDialogState) = React.useState(() => Hidden)
  let hideDialog = _ => setDialogState(_ => Hidden)

  {
    switch currentUserAccountDoc.data {
    | Some(currentUser) =>
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
          headingSlot={React.string(currentUser.name)}
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
            {switch currentUser.places->Js.Dict.entries {
            | [] => <p> {React.string("Nemáte žádná místa")} </p>
            | placeEntries =>
              <nav>
                <ul className={Styles.list.base}>
                  {placeEntries
                  ->Array.map(((id, name)) => {
                    let stringId = String.make(id)
                    <li key={stringId}>
                      <a
                        {...RouterUtils.createAnchorProps(`./${stringId}`)}
                        className={Styles.utility.breakout}>
                        {React.string(name)}
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
            initialPersonName={currentUser.name}
            onDismiss={hideDialog}
            onSubmit={async values => {
              let placeDoc = Firebase.seedDoc(Db.placeCollection(firestore))
              let personDoc = Firebase.seedDoc(Db.placePersonsCollection(firestore, placeDoc.id))
              let userDoc = Db.accountDoc(firestore, Db.getUid(currentUser)->Option.getExn)
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
                },
                {},
              )
              ->Firebase.WriteBatch.set(
                personDoc,
                {
                  account: Some(userDoc)->Null.fromOption,
                  createdAt: now,
                  name: values.personName,
                  transactions: [],
                },
                {},
              )
              ->Firebase.WriteBatch.update(
                userDoc,
                Object.empty()->ObjectUtils.setIn(`places.${placeDoc.id}`, values.placeName),
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
