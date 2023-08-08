@react.component
let make = (~children) => {
  let signInStatus = Reactfire.useSigninCheck()

  switch signInStatus.data {
  | None => React.null
  | Some({user: maybeUser}) =>
    switch maybeUser->Null.toOption {
    | None
    | // We only use anonymous users for WebAuthn as intermediary step
    Some({isAnonymous: true}) =>
      <Unauthenticated />
    | Some(user) => <Onboarding user> {children} </Onboarding>
    }
  }
}
