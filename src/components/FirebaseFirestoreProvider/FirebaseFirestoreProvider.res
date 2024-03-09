let initializedFirestore: ref<option<Firebase.firestore>> = ref(None)

@react.component
let make = (~children) => {
  open Reactfire
  open Firebase

  let isStandaloneModeStatus = DomUtils.useIsStandaloneMode()
  let {status, data: firestore} = useInitFirestore(async app => {
    switch initializedFirestore.contents {
    | Some(firestore) => firestore
    | None => {
        let isStandaloneMode = isStandaloneModeStatus.data->Option.getOr(false)
        let firestore = initializeFirestore(
          app,
          !isStandaloneMode && AppStorage.getThrustDevice() === None
            ? {}
            : {
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
  | #loading => React.null
  | #success =>
    switch firestore {
    | None => React.null
    | Some(firestore) => <FirestoreProvider sdk={firestore}> ...children </FirestoreProvider>
    }
  }
}
