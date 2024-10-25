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
          UserRoles.roleFromInt(shareLink.role)
          ->Option.map(UserRoles.roleI18n)
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
              className={Styles.button.variantPrimary}
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
            <a className={Styles.button.variantPrimary} href="/misto">
              {React.string("Můj seznam míst")}
            </a>
          </div>
        </>
      }}
    </div>
  }
}

let redirectToPlace = placeId => {
  RescriptReactRouter.replace(`/misto/${placeId}`)
}

let pageDataRx = (auth, firestore, ~linkId) => {
  open Rxjs
  let currentUserRx = Rxfire.user(auth)->pipe(keepMap(Null.toOption))
  let shareLinkRx = Rxfire.docData(Db.ShareLink.document(firestore, linkId))
  let shareLinkPlaceRx = shareLinkRx->pipe(
    switchMap((maybeShareLink: option<FirestoreModels.shareLink>) => {
      switch maybeShareLink {
      | None => return(None)
      | Some(shareLink) => Rxfire.docData(Db.placeDocument(firestore, shareLink.place))
      }
    }),
  )
  combineLatest2(currentUserRx, shareLinkPlaceRx)
  ->op(first())
  ->op(
    tap(((currentUser, maybeShareLinkPlace): (Firebase.User.t, option<FirestoreModels.place>)) => {
      switch maybeShareLinkPlace {
      | None => ()
      | Some(shareLinkPlace) => {
          let userAlreadyInPlace = shareLinkPlace.accounts->Dict.get(currentUser.uid)->Option.isSome
          if userAlreadyInPlace {
            Db.ShareLink.delete(firestore, ~linkId)->ignore
            redirectToPlace(Db.getUid(shareLinkPlace))
          }
        }
      }
    }),
  )
  ->subscribeFn(_ => ())
  ->ignore
  combineLatest3(currentUserRx, shareLinkRx, shareLinkPlaceRx)
}

@react.component
let make = (~linkId) => {
  let auth = Reactfire.useAuth()
  let firestore = Reactfire.useFirestore()
  let pageDataStatus = Reactfire.useObservable(
    ~observableId=`page_ShareLinkResolver_${linkId}`,
    ~source=pageDataRx(auth, firestore, ~linkId),
  )

  switch pageDataStatus.data {
  | Some((currentUser, Some(shareLink), Some(shareLinkPlace))) =>
    let (acceptInviteState, acceptInviteSend) = ReactUpdate.useReducer((state, action) => {
      switch (action, state) {
      | (Run, Error(_)) // allow retry
      | (Run, Ready) =>
        ReactUpdate.UpdateWithSideEffects(
          Pending,
          ({send}) => {
            Db.ShareLink.acceptInvitation(firestore, ~linkId, ~userId=currentUser.uid)
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
            redirectToPlace(shareLink.place)
            None
          },
        )
      | (Rejected(error), Pending) => ReactUpdate.Update(Error(error))
      | _ => ReactUpdate.NoUpdate
      }
    }, Ready)
    <Pure
      data=Some(shareLink, shareLinkPlace)
      loading={acceptInviteState == Pending}
      onAccept={_ => acceptInviteSend(Run)}
    />
  | _ => <Pure data={None} />
  }
}
