@react.component
let make = (~children) => {
  open Firebase

  let app = useFirebaseApp()
  let appCheck = initializeAppCheck(
    app,
    {
      provider: createReCaptchaV3Provider(appCheckToken),
      isTokenAutoRefreshEnabled: true,
    },
  )
  let auth = app->getAuth

  let {status, data: firestore} = useInitFirestore(async app => {
    let firestore = app->getFirestore
    Js.log("Enabling offline persistence")
    try {
      await firestore->enableMultiTabIndexedDbPersistence
    } catch {
    | Js.Exn.Error(err) => Js.log(err)
    }
    firestore
  })

  switch status {
  | #error => <div> {React.string("Some error hapenned")} </div>
  | #success =>
    switch firestore {
    | None => React.null
    | Some(firestore) =>
      <AppCheckProvider sdk=appCheck>
        <AuthProvider sdk=auth>
          <FirestoreProvider sdk={firestore}> ...children </FirestoreProvider>
        </AuthProvider>
      </AppCheckProvider>
    }
  }
}
