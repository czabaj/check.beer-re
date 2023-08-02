@react.component
let make = (~children) => {
  let signInStatus = Reactfire.useSigninCheck()

  switch signInStatus.data {
  | None => React.null
  | Some({user: maybeUser}) =>
    switch maybeUser->Null.toOption {
    | None => <Unauthenticated />
    | Some(user) =>
      if user.displayName->Null.mapWithDefault("", String.trim) === "" {
        <CreateAccount user />
      } else {
        children
      }
    }
  }
}
