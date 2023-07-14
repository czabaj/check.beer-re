open Firebase

type firebaseConfig
@module("./firebaseConfig")
external firebaseConfig: firebaseConfig = "firebaseConfig"

module FirebaseAppProvider = {
  @react.component @module("reactfire")
  external make: (
    ~firebaseConfig: firebaseConfig=?,
    ~children: React.element,
    ~suspense: bool=?,
  ) => React.element = "FirebaseAppProvider"
}

module AuthProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: Auth.t, ~children: React.element) => React.element = "AuthProvider"
}

type observableStatus<'a> = {status: @string [#error | #loading | #success], data: option<'a>}

@module("reactfire")
external useAuth: unit => Auth.t = "useAuth"

@module("reactfire")
external useFirestoreDocData: (
  documentReference<'a>,
  @as(json`{ "idField": "uid" }`) _,
) => observableStatus<'a> = "useFirestoreDocData"

type reactfireOptions<'a> = {
  // force usage of fieldId
  idField: @string [#uid],
  initialData?: 'a,
  suspense?: bool,
}

@module("reactfire")
external useFirestoreDocDataWithOptions: (
  documentReference<'a>,
  ~options: option<reactfireOptions<'a>>,
) => observableStatus<'a> = "useFirestoreDocData"

@module("reactfire")
external useFirestoreCollectionData: (
  query<'a>,
  @as(json`{ "idField": "uid" }`) _,
) => observableStatus<array<'a>> = "useFirestoreCollectionData"

module FirestoreProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: firestore, ~children: React.element) => React.element = "FirestoreProvider"
}

@module("reactfire")
external useFirebaseApp: unit => FirebaseApp.t = "useFirebaseApp"

@module("reactfire")
external useInitFirestore: (FirebaseApp.t => promise<firestore>) => observableStatus<_> =
  "useInitFirestore"

@module("reactfire")
external useFirestore: unit => firestore = "useFirestore"

@module("reactfire")
external useObservable: (
  ~observableId: string,
  ~source: Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>,
) => observableStatus<'a> = "useObservable"
