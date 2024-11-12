type views = ForgotPassword(string) | ForgotPasswordSent(string) | SignIn | SignUp

@react.component
let make = () => {
  open Firebase.Auth
  let app = Reactfire.useFirebaseApp()
  let auth = Reactfire.useAuth()
  let (view, setView) = React.useState(() => SignIn)
  let (signInWithPasskey, runSignInWithPasskey) = Hooks.usePromise(() => {
    // TODO: upgrade the FirebaseWebAuthn and deploy to "europe-west3"
    let functions = app->Firebase.Functions.getFunctionsInRegion(`us-central1`)
    FirebaseWebAuthn.signInWithPasskey(auth, functions)
  })
  let isOnlineStatus = DomUtils.useIsOnline()
  let isOnline = isOnlineStatus.data
  let supportsWebAuthn = DomUtils.useSuportsPlatformWebauthn()
  let webAuthn = AppStorage.useLocalStorage(AppStorage.keyWebAuthn)->fst
  let webAuthnReady = supportsWebAuthn && webAuthn === Some("1")
  let startWebAuthnAutomatically = React.useRef(isOnline === Some(true))
  React.useEffect0(() => {
    if startWebAuthnAutomatically.current {
      startWebAuthnAutomatically.current = false
      if webAuthnReady {
        runSignInWithPasskey()
      }
    }
    None
  })

  switch view {
  | ForgotPassword(initialEmail) =>
    <ForgottenPasswordForm
      isOnline
      initialEmail
      onGoBack={() => setView(_ => SignIn)}
      onSubmit={values => {
        sendPasswordResetEmail(auth, ~email=values.email)->Promise.then(_ => {
          setView(_ => ForgotPasswordSent(values.email))
          Promise.resolve()
        })
      }}
    />
  | ForgotPasswordSent(email) =>
    <ForgottenPasswordSent email onGoBack={() => setView(_ => SignIn)} />
  | SignIn =>
    <SignInForm
      isOnline
      loadingOverlay={signInWithPasskey.state === #pending}
      onForgottenPassword={email => setView(_ => ForgotPassword(email))}
      onSignInWithGoogle={() => {
        signInWithRedirect(auth, FederatedAuthProvider.googleAuthProvider())
        ->Promise.catch(error => {
          let exn = Js.Exn.asJsExn(error)->Option.getExn
          LogUtils.captureException(exn)
          Promise.reject(error)
        })
        ->ignore
      }}
      onSignInWithPasskey={!webAuthnReady ? None : Some(runSignInWithPasskey)}
      onSignInWithPassword={({email, password}) => {
        signInWithEmailAndPassword(auth, ~email, ~password)->Promise.thenResolve(_ => ())
      }}
      onSignUp={() => setView(_ => SignUp)}
    />
  | SignUp =>
    <SignUpForm
      isOnline
      onGoBack={() => setView(_ => SignIn)}
      onSubmit={({email, password}) => {
        createUserWithEmailAndPassword(auth, ~email, ~password)->Promise.thenResolve(_ => ())
      }}
    />
  }
}
