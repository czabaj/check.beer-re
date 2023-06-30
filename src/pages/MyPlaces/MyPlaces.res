@react.component
let make = () => {
  let currentUserAccountDoc = Db.useCurrentUserAccountDocData()
  <div>
    <h2> {React.string("Moje mista")} </h2>
    <a {...RouterUtils.createAnchorProps("./pridat")}> {React.string("Přidat místo")} </a>
    <div>
      {switch currentUserAccountDoc.data {
      | Some(currentUser) =>
        switch currentUser.places->Js.Dict.entries {
        | [] => React.string("Nemáte žádná místa")
        | placeEntries =>
          <ul>
            {placeEntries
            ->Array.map(((id, name)) => {
              let stringId = String.make(id)
              <li key={stringId}>
                <a {...RouterUtils.createAnchorProps(`./${stringId}`)}> {React.string(name)} </a>
              </li>
            })
            ->React.array}
          </ul>
        }
      | _ => React.null
      }}
    </div>
  </div>
}
