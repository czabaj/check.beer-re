open Firebase

type firebaseConfig
@module("./firebaseConfig")
external firebaseConfig: firebaseConfig = "firebaseConfig"

module AnalyticsProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: Firebase.Analytics.t, ~children: React.element) => React.element =
    "AnalyticsProvider"
}

module AuthProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: Auth.t, ~children: React.element) => React.element = "AuthProvider"
}

module FirebaseAppProvider = {
  @react.component @module("reactfire")
  external make: (
    ~firebaseConfig: firebaseConfig=?,
    ~children: React.element,
    ~suspense: bool=?,
  ) => React.element = "FirebaseAppProvider"
}

module FunctionsProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: Firebase.Functions.t, ~children: React.element) => React.element =
    "FunctionsProvider"
}

type observableStatus<'a> = {
  data: option<'a>,
  error: option<Js.Exn.t>,
  firstValuePromise: promise<unit>,
  hasEmmited: bool,
  isComplete: bool,
  status: @string [#error | #loading | #success],
}

@module("reactfire")
external useAnalytics: unit => Analytics.t = "useAnalytics"

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
external useFunctions: unit => Firebase.Functions.t = "useFunctions"

@module("reactfire")
external useObservable: (
  ~observableId: string,
  ~source: Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>,
) => observableStatus<'a> = "useObservable"

type signInCheckResult = {user: Null.t<Firebase.User.t>}
@module("reactfire")
external useSigninCheck: unit => observableStatus<signInCheckResult> = "useSigninCheck"
