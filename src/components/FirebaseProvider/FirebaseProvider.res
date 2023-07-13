let initializedFirestore: ref<option<Firebase.firestore>> = ref(None)

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
  let auth = app->Auth.getAuth

  let {status, data: firestore} = useInitFirestore(async app => {
    switch initializedFirestore.contents {
    | Some(firestore) => firestore
    | None => {
        let firestore = initializeFirestore(
          app,
          {
            localCache: FirestoreLocalCache.persistentLocalCache({
              tabManager: FirestoreLocalCache.PersistentTabManager.persistentMultipleTabManager(.),
            }),
          },
        )
        // if %raw(`import.meta.env.DEV && window.localStorage.getItem('USE_EMULATOR') === '1'`) {
        //   Firebase.connectFirestoreEmulator(. firestore, "127.0.0.1", 9090)
        //   Firebase.connectAuthEmulator(. auth, "http://localhost:9099")
        // }
        initializedFirestore := Some(firestore)
        firestore
      }
    }
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
