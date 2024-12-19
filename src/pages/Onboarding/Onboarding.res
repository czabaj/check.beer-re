type view = NickName | ThrustDevice | BiometricAuthn

@react.component
let make = (~children, ~user: Firebase.User.t) => {
  let app = Reactfire.useFirebaseApp()
  let auth = Reactfire.useAuth()
  let supportsWebAuthn = DomUtils.useSuportsPlatformWebauthn()
  let (webAuthn, setWebAuthn) = AppStorage.useLocalStorage(AppStorage.keyWebAuthn)
  let (thrustDevice, setThrustDevice) = AppStorage.useLocalStorage(AppStorage.keyThrustDevice)
  let view = React.useMemo4(() => {
    if thrustDevice === None {
      Some(ThrustDevice)
    } else if thrustDevice === Some("1") && supportsWebAuthn && webAuthn === None {
      Some(BiometricAuthn)
    } else if user.displayName->Null.mapOr("", String.trim) === "" {
      Some(NickName)
    } else {
      None
    }
  }, (supportsWebAuthn, thrustDevice, user.displayName, webAuthn))
  let (setupWebAuthn, runSetupWebAuthn) = Hooks.usePromise(async () => {
    let email = user.email->Null.getExn
    try {
      // TODO: upgrade the FirebaseWebAuthn and deploy to "europe-west3"
      let functions = app->Firebase.Functions.getFunctionsInRegion(#"europe-central2")
      let _ = await FirebaseWebAuthn.linkWithPasskey(auth, functions, email)
      setWebAuthn(Some("1"))
    } catch {
    | error =>
      switch error->FirebaseWebAuthn.toFirebaseWebAuthnError {
      | FirebaseWebAuthn.CancelledByUser => ()
      | FirebaseWebAuthn.NoOperationNeeded =>
        // Device set-up already, just mark it as done in the storage
        setWebAuthn(Some("1"))
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
        setWebAuthn(Some("0"))
      }}
      setupError=?{setupWebAuthn.error}
    />
  | Some(NickName) =>
    <OnboardingNickName
      initialName={user.displayName->Null.getOr("")}
      onSubmit={async values => {
        let _ = await Firebase.Auth.updateProfile(user, {displayName: values.name})
        let _ = await user->Firebase.User.reload
      }}
    />
  | Some(ThrustDevice) =>
    <OnboardingThrustDevice
      mentionWebAuthn={supportsWebAuthn}
      onSkip={() => setThrustDevice(Some("0"))}
      onThrust={() => {
        setThrustDevice(Some("1"))
      }}
    />
  }
}
