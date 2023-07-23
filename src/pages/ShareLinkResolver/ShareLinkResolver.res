type acceptInviteState = Ready | Pending | Success | Error(exn)

type acceptInviteAction = Run | Resolved | Rejected(exn)

module Pure = {
  @gentype @react.component
  let make = (
    ~data: option<(FirestoreModels.shareLink, FirestoreModels.place)>,
    ~loading=?,
    ~onAccept=?,
  ) => {
    <div className={Styles.page.centered}>
      <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
      <h2> {React.string("Pozvánka")} </h2>
      {switch (data, onAccept) {
      | (Some(shareLink, place), Some(handleAccept)) =>
        let role =
          shareLink.role
          ->FirestoreModels.roleFromJs
          ->Option.map(FirestoreModels.roleI18n)
          ->Option.getExn
        <>
          <p>
            {React.string(`Dovolujeme si vás pozvat do výčeního místa `)}
            <b> {React.string(place.name)} </b>
            {React.string(`.  Vaše role bude `)}
            <i> {React.string(role)} </i>
          </p>
          <div>
            <button
              className={`${Styles.button.base} ${Styles.button.variantPrimary}`}
              disabled=?loading
              onClick={_ => handleAccept()}
              type_="button">
              {React.string("Přijmout pozvání")}
            </button>
          </div>
        </>
      | _ =>
        <>
          <p>
            {React.string(`Omlouváme se, ale pozvánka, `)}
            <b> {React.string(`již není platná`)} </b>
            {React.string(`. Možná jste jí už přijali, nebo vypršela její platnost.`)}
          </p>
          <p>
            {React.string(`Podívejte se, jestli místo, kam se chcete přihlásit, nefiguruje na vašem seznamu míst. Když
            tam místo nenajdete, požádejte správce místa aby vám poslal novou pozvánku.`)}
          </p>
          <div>
            <a className={`${Styles.button.base} ${Styles.button.variantPrimary}`} href="/misto">
              {React.string("Můj seznam míst")}
            </a>
          </div>
        </>
      }}
    </div>
  }
}

let pageDataRx = (firestore, ~linkId) => {
  open Rxjs
  Rxfire.docData(Db.ShareLink.document(firestore, linkId))->pipe(
    mergeMap((shareLink: FirestoreModels.shareLink) => {
      Rxfire.docData(Db.placeDocument(firestore, shareLink.place))->pipe(
        map((place, _) => (shareLink, place)),
      )
    }),
  )
}

@react.component
let make = (~linkId) => {
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId=`page_ShareLinkResolver_${linkId}`,
    ~source=pageDataRx(firestore, ~linkId),
  )
  let {currentUser} = Reactfire.useAuth()
  switch (pageDataStatus.data, currentUser->Null.toOption) {
  | (Some(data), Some({uid: userId})) =>
    let (acceptInviteState, acceptInviteSend) = ReactUpdate.useReducer(Ready, (action, state) => {
      switch (action, state) {
      | (Run, Error(_)) // allow retry
      | (Run, Ready) =>
        ReactUpdate.UpdateWithSideEffects(
          Pending,
          ({send}) => {
            Db.ShareLink.acceptInvitation(firestore, ~linkId, ~userId)
            ->Promise.then(() => {
              send(Resolved)
              Promise.resolve()
            })
            ->Promise.catch(error => {
              send(Rejected(error))
              Promise.resolve()
            })
            ->ignore
            None
          },
        )
      | (Resolved, Pending) =>
        ReactUpdate.UpdateWithSideEffects(
          Success,
          _ => {
            let shareLink = data->fst
            RescriptReactRouter.replace(`/misto/${shareLink.place}`)
            None
          },
        )
      | (Rejected(error), Pending) => ReactUpdate.Update(Error(error))
      | _ => ReactUpdate.NoUpdate
      }
    })
    <Pure
      data=pageDataStatus.data
      loading={acceptInviteState == Pending}
      onAccept={_ => acceptInviteSend(Run)}
    />
  | _ => <Pure data={None} />
  }
}
