let signInDataRx = (auth, firestore) => {
  open Rxjs
  Rxfire.user(auth)->pipe(
    mergeMap((maybeUser: Null.t<Firebase.User.t>) => {
      switch maybeUser->Null.toOption {
      | None => return((None, None))
      | Some(user) =>
        Db.userAccountsByEmailRx(firestore, ~email=user.email)->pipe(
          map((userAccounts, _) => (Some(user), userAccounts->Array.at(0))),
        )
      }
    }),
  )
}

@react.component
let make = (~children) => {
  let auth = Reactfire.useAuth()
  let firestore = Reactfire.useFirestore()
  let signInDataStatus = Reactfire.useObservable(
    ~observableId="signInData",
    ~source=signInDataRx(auth, firestore),
  )

  switch signInDataStatus.data {
  | Some((Some(_user), Some(_account))) => children
  | Some((Some(user), None)) => <CreateAccount user />
  | Some(None, _) => <Unauthenticated />
  | _ => React.null
  }
}
