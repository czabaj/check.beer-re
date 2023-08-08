@react.component
let make = (~children) => {
  open Firebase
  open Reactfire
  let app = useFirebaseApp()
  let appCheck = initializeAppCheck(
    app,
    {
      provider: createReCaptchaV3Provider(appCheckToken),
      isTokenAutoRefreshEnabled: true,
    },
  )
  let auth = app->Auth.getAuth
  Auth.setLanguageCode(auth, "cs")

  let functions = app->Functions.getFunctions

  <AppCheckProvider sdk=appCheck>
    <AuthProvider sdk=auth>
      <FunctionsProvider sdk=functions> {children} </FunctionsProvider>
    </AuthProvider>
  </AppCheckProvider>
}
