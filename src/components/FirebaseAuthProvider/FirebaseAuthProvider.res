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

  <AppCheckProvider sdk=appCheck>
    <AuthProvider sdk=auth> {children} </AuthProvider>
  </AppCheckProvider>
}
