type view = NickName | ThrustDevice | BiometricAuthn

@react.component
let make = (~children, ~user: Firebase.User.t) => {
  let auth = Reactfire.useAuth()
  let firestore = Reactfire.useFirestore()
  let functions = Reactfire.useFunctions()
  let supportsWebAuthn = DomUtils.useSuportsPlatformWebauthn()
  let (webAuthn, setWebAuthn) = AppStorage.useLocalStorage(AppStorage.keyWebAuthn)
  let (thrustDevice, setThrustDevice) = AppStorage.useLocalStorage(AppStorage.keyThrustDevice)
  let webAuthnUserStatus = Reactfire.useFirestoreDocDataWithOptions(
    Db.webAuthnUsersDocument(firestore, user.uid),
    ~options=Some({idField: #uid, suspense: false}),
  )
  let webAuthnSkipIfEnabledOnServerDeps = (
    supportsWebAuthn,
    thrustDevice,
    webAuthn,
    webAuthnUserStatus.data,
  )
  React.useEffect4(() => {
    switch webAuthnSkipIfEnabledOnServerDeps {
    | (true, Some("1"), None, Some(_)) => setWebAuthn(. Some("1"))
    | _ => ()
    }
    None
  }, webAuthnSkipIfEnabledOnServerDeps)
  let view = React.useMemo4(() => {
    if thrustDevice === None {
      Some(ThrustDevice)
    } else if thrustDevice === Some("1") && supportsWebAuthn && webAuthn === None {
      Some(BiometricAuthn)
    } else if user.displayName->Null.mapWithDefault("", String.trim) === "" {
      Some(NickName)
    } else {
      None
    }
  }, (supportsWebAuthn, thrustDevice, user.displayName, webAuthn))
  let (setupWebAuthn, runSetupWebAuthn) = Hooks.usePromise(async () => {
    let email = user.email->Null.getExn
    try {
      let _ = await FirebaseWebAuthn.linkWithPasskey(. auth, functions, email)
      setWebAuthn(. Some("1"))
    } catch {
    | error =>
      switch error->FirebaseWebAuthn.toFirebaseWebAuthnError {
      | FirebaseWebAuthn.CancelledByUser => ()
      | FirebaseWebAuthn.NoOperationNeeded =>
        // Device set-up already, just mark it as done in the storage
        setWebAuthn(. Some("1"))
      | Js.Exn.Error(exn) => {
          LogUtils.captureException(exn)
          raise(error)
        }
      | _ => raise(error)
      }
    }
  })
  switch view {
  | None => children
  | Some(BiometricAuthn) =>
    <BiometricAuthn
      loadingOverlay={setupWebAuthn.state === #pending}
      onSetupAuthn={runSetupWebAuthn}
      onSkip={() => {
        setWebAuthn(. Some("0"))
      }}
      setupError=?{setupWebAuthn.error}
    />
  | Some(NickName) =>
    <OnboardingNickName
      initialName={user.displayName->Null.getWithDefault("")}
      onSubmit={async values => {
        let _ = await Firebase.Auth.updateProfile(user, {displayName: values.name})
        let _ = await user->Firebase.User.reload
      }}
    />
  | Some(ThrustDevice) =>
    <OnboardingThrustDevice
      mentionWebAuthn={supportsWebAuthn}
      onSkip={() => setThrustDevice(. Some("0"))}
      onThrust={() => {
        setThrustDevice(. Some("1"))
      }}
    />
  }
}
