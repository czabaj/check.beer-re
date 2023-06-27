type firebaseConfig
@module("./firebaseConfig")
external firebaseConfig: firebaseConfig = "firebaseConfig"

module FirebaseAppProvider = {
  @react.component @module("reactfire")
  external make: (
    ~firebaseConfig: firebaseConfig,
    ~children: React.element,
    ~suspense: bool=?,
  ) => React.element = "FirebaseAppProvider"
}

module FirebaseOptions = {
  type t
}

module FirebaseApp = {
  type t = {options: FirebaseOptions.t}
}

@module("reactfire")
external useFirebaseApp: unit => FirebaseApp.t = "useFirebaseApp"

// @module("firebase/app")
// external initializeApp: firebaseConfig => firebaseApp = "initializeApp"

// type analytics
// @module("firebase/analytics")
// external getAnalytics: firebaseApp => analytics = "getAnalytics"

type firestore
@module("firebase/firestore")
external getFirestore: FirebaseApp.t => firestore = "getFirestore"

module FirestoreProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: firestore, ~children: React.element) => React.element = "FirestoreProvider"
}

// TODO: Bind TS string union `status`
type observableStatus<'a> = {status: @string [#error | #success], data: option<'a>}
@module("reactfire")
external useInitFirestore: (FirebaseApp.t => promise<firestore>) => observableStatus<_> =
  "useInitFirestore"

@module("reactfire")
external useFirestore: unit => firestore = "useFirestore"

@module("firebase/firestore")
external enableIndexedDbPersistence: firestore => promise<unit> = "enableIndexedDbPersistence"

@module("firebase/firestore")
external enableMultiTabIndexedDbPersistence: firestore => promise<unit> =
  "enableMultiTabIndexedDbPersistence"

type documentReference<'a> = {
  id: string
}
@module("firebase/firestore")
external doc: (firestore, ~path: string) => documentReference<'a> = "doc"

type collectionReference<'a>
@module("firebase/firestore")
external collection: (firestore, ~path: string) => collectionReference<'a> = "collection"

type query<'a>
type queryConstraint
@module("firebase/firestore") @variadic
external query: (collectionReference<'a>, array<queryConstraint>) => query<'a> = "query"

@module("firebase/firestore")
external orderBy: (string, ~direction: [#asc | #desc]) => queryConstraint = "orderBy"

type documentSnapshot<'a> = {exists: (. unit) => bool, data: (. unit) => 'a}
@module("firebase/firestore")
external getDoc: documentReference<'a> => promise<documentSnapshot<'a>> = "getDoc"

@module("firebase/firestore")
external setDoc: (documentReference<'a>, 'a) => promise<unit> = "setDoc"

@module("firebase/firestore")
external updateDoc: (documentReference<'a>, 'a) => promise<unit> = "updateDoc"

@module("firebase/firestore")
external addDoc: (collectionReference<'a>, 'a) => promise<documentReference<'a>> = "addDoc"

@module("firebase/firestore")
external where: (
  string,
  [#"<" | #"<=" | #"==" | #">=" | #">" | #array_contains],
  'a,
) => queryConstraint = "where"

type aggregateSpecData = {count: int}
type aggregateQuerySnapshot = {data: (. unit) => aggregateSpecData}
@module("firebase/firestore")
external getCountFromServer: collectionReference<'a> => promise<aggregateQuerySnapshot> =
  "getCountFromServer"

type reactFireOptions<'a> = {
  idField?: string,
  initialData?: 'a,
  suspense?: bool,
}

@module("reactfire")
external useFirestoreDocData: documentReference<'a> => observableStatus<'a> = "useFirestoreDocData"

@module("reactfire")
external useFirestoreCollectionData: (
  query<'a>,
  reactFireOptions<'a>,
) => observableStatus<array<'a>> = "useFirestoreCollectionData"

module User = {
  @deriving(accessors)
  type info = {
    uid: string,
    providerId: string,
    displayName: option<string>,
    email: option<string>,
  }
  type t = {
    uid: string,
    displayName: option<string>,
    email: option<string>,
    emailVerified: bool,
    photoURL: option<string>,
    providerData: array<info>,
  }
}

module Auth = {
  type t = {app: FirebaseApp.t}
  type update = {displayName?: string, photoURL?: string}

  @send
  external onAuthStateChanged: (t, 'user) => 'unsubscribe = "onAuthStateChanged"

  @module("firebase/auth")
  external signOut: t => promise<unit> = "signOut"

  @module("firebase/auth")
  external updateProfile: (User.t, update) => promise<unit> = "updateProfile"

  module EmailAuthProvider = {
    let providerID = "password"
  }
  module GithubAuthProvider = {
    let providerID = "github.com"
  }
  module GoogleAuthProvider = {
    let providerID = "google.com"
  }
}

@module("firebase/auth")
external getAuth: FirebaseApp.t => Auth.t = "getAuth"

module AuthProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: Auth.t, ~children: React.element) => React.element = "AuthProvider"
}

@module("reactfire")
external useAuth: unit => Auth.t = "useAuth"

// TODO: The domain modeling seems a bit off--what does it mean when signedIn is false and there is a user?
type signInCheckResult = {signedIn: bool, user: User.t}
@module("reactfire")
external useSigninCheck: unit => observableStatus<signInCheckResult> = "useSigninCheck"

type appCheckToken
@module("./firebaseConfig")
external appCheckToken: appCheckToken = "APP_CHECK_TOKEN"

type reCaptchaV3Provider
@new @module("firebase/app-check")
external createReCaptchaV3Provider: appCheckToken => reCaptchaV3Provider = "ReCaptchaV3Provider"

type appCheck
type appCheckConfig = {provider: reCaptchaV3Provider, isTokenAutoRefreshEnabled: bool}
@module("firebase/app-check")
external initializeAppCheck: (FirebaseApp.t, appCheckConfig) => appCheck = "initializeAppCheck"

module AppCheckProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: appCheck, ~children: React.element) => React.element = "AppCheckProvider"
}

module Timestamp = {
  type t
  @new @module("firebase/firestore")
  external make: unit => t = "Timestamp"
  @send
  external toDate: t => Js.Date.t = "toDate"
  @send
  external toMillis: t => float = "toMillis"
  @module("firebase/firestore") @scope("Timestamp")
  external fromDate: Js.Date.t => t = "fromDate"
  @module("firebase/firestore") @scope("Timestamp")
  external fromMillis: float => t = "fromMillis"
}

module StyledFirebaseAuth = {
  @react.component @module("react-firebaseui")
  external make: (~uiConfig: 'uiConfig, ~firebaseAuth: 'a) => React.element = "StyledFirebaseAuth"
}

module FirebaseCompat = {
  type firebase

  @module("firebase/compat/app")
  external firebase: firebase = "default"

  @send
  external initializeApp: (firebase, FirebaseOptions.t) => FirebaseApp.t = "initializeApp"
}

type functions
@module("firebase/functions")
external getFunctions: (FirebaseApp.t, @as("asia-northeast3") _) => functions = "getFunctions"

type callResult<'a> = {data: 'a}
@module("firebase/functions")
external httpsCallable: (functions, string) => (. 'a) => promise<callResult<'b>> = "httpsCallable"

@module("reactfire")
external useObservable: (
  ~observableId: string,
  ~source: Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>,
) => observableStatus<'a> = "useObservable"

@module("rxfire/auth")
external userRx: Auth.t => Rxjs.t<Rxjs.foreign, Rxjs.void, Js.Nullable.t<User.t>> = "user"

@module("rxfire/firestore")
external collectionDataRx: (
  query<'a>,
  reactFireOptions<'a>,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, array<'a>> = "collectionData"

type authProvider

@module("firebase/auth")
external googleAuthProvider: authProvider = "GoogleAuthProvider"

type userCredential = {
  user: User.t,
  providerId: Js.Nullable.t<string>,
  operationType: @string [#link | #reauthenticate | #signIn],
}

@module("firebase/auth")
external signInWithPopup: (Auth.t, authProvider) => promise<userCredential> = "signInWithPopup"
