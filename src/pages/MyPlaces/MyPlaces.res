@react.component
let make = () => {
  let currentUserAccountDoc = Db.useCurrentUserAccountDocData()
  let auth = Firebase.useAuth()

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
            buttonsSlot={<a
              {...RouterUtils.createAnchorProps("./pridat")} className={`${Styles.button.button} `}>
              {React.string("Přidat místo")}
            </a>}
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
      </div>
    | _ => React.null
    }
  }
}
