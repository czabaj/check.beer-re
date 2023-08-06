type views = ForgotPassword(string) | ForgotPasswordSent(string) | SignIn | SignUp

@react.component
let make = () => {
  open Firebase.Auth
  let auth = Reactfire.useAuth()
  let isStandaloneModeStatus = DomUtils.useIsStandaloneMode()
  let (view, setView) = React.useState(() => SignIn)

  switch view {
  | ForgotPassword(initialEmail) =>
    <ForgottenPasswordForm
      initialEmail
      onGoBack={() => setView(_ => SignIn)}
      onSubmit={values => {
        sendPasswordResetEmail(. auth, ~email=values.email)->Promise.then(_ => {
          AppStorage.setPendingEmail(values.email)
          setView(_ => ForgotPasswordSent(values.email))
          Promise.resolve()
        })
      }}
    />
  | ForgotPasswordSent(email) =>
    <ForgottenPasswordSent email onGoBack={() => setView(_ => SignIn)} />
  | SignIn =>
    <SignInForm
      initialEmail={AppStorage.getRememberEmail()->Option.getWithDefault("")}
      isStandaloneMode=isStandaloneModeStatus.data
      onForgottenPassword={email => setView(_ => ForgotPassword(email))}
      onGoogleAuth={() => {
        signInWithRedirect(. auth, FederatedAuthProvider.googleAuthProvider())
        ->Promise.catch(error => {
          Js.log(error)
          Promise.reject(error)
        })
        ->ignore
      }}
      onPasswordAuth={({email, password}) => {
        signInWithEmailAndPassword(. auth, ~email, ~password)->Promise.then(_ => {
          if AppStorage.getThrustDevice()->Option.isSome {
            AppStorage.setRememberEmail(email)
          }
          Promise.resolve()
        })
      }}
      onSignUp={() => setView(_ => SignUp)}
    />
  | SignUp =>
    <SignUpForm
      onGoBack={() => setView(_ => SignIn)}
      onSubmit={({email, password}) => {
        createUserWithEmailAndPassword(. auth, ~email, ~password)->Promise.then(_ => {
          if AppStorage.getThrustDevice()->Option.isSome {
            AppStorage.setRememberEmail(email)
          }
          Promise.resolve()
        })
      }}
    />
  }
}
