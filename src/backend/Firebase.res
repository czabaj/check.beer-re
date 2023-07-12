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

@genType.import("firebase/firestore") @genType.as("Firestore")
type firestore
@module("firebase/firestore")
external getFirestore: FirebaseApp.t => firestore = "getFirestore"

@module("firebase/firestore")
external documentId: unit => string = "documentId"

module FirestoreProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: firestore, ~children: React.element) => React.element = "FirestoreProvider"
}

// the #loading is missing because we are using Suspense mode
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

type updateTag = ArrayUnion | ArrayRemove | Increment
@module("firebase/firestore") @variadic
external arrayUnion: array<'a> => updateTag = "arrayUnion"

@module("firebase/firestore")
external incrementInt: int => updateTag = "increment"

@genType.import("firebase/firestore") @genType.as("DocumentReference")
type documentReference<'a> = {id: string}
@module("firebase/firestore")
external doc: (firestore, ~path: string) => documentReference<'a> = "doc"

@genType.import("firebase/firestore") @genType.as("CollectionReference")
type collectionReference<'a>
@module("firebase/firestore")
external collection: (firestore, ~path: string) => collectionReference<'a> = "collection"

@module("firebase/firestore")
external seedDoc: (collectionReference<'a>) => documentReference<'a> = "doc"

type query<'a>
type queryConstraint
@module("firebase/firestore") @variadic
external query: (collectionReference<'a>, array<queryConstraint>) => query<'a> = "query"

@module("firebase/firestore")
external orderBy: (string, ~direction: [#asc | #desc]) => queryConstraint = "orderBy"

@module("firebase/firestore")
external limit: int => queryConstraint = "limit"

@module("firebase/firestore")
external startAfter: 'a => queryConstraint = "startAfter"

type snapshotOptions = {serverTimestamps?: @string [#estimate | #previous | #none]}

@module("firebase/firestore")
external deleteField: unit => 'a = "deleteField"

@module("firebase/firestore")
external deleteDoc: documentReference<'a> => promise<unit> = "deleteDoc"

@module("firebase/firestore")
external serverTimestamp: unit => 'a = "serverTimestamp"

type documentSnapshot<'a> = {data: (. snapshotOptions) => 'a, exists: (. unit) => bool, id: string}
@module("firebase/firestore")
external getDoc: documentReference<'a> => promise<documentSnapshot<'a>> = "getDoc"

type querySnapshot<'a> = {
  docs: array<documentSnapshot<'a>>,
  forEach: (. documentSnapshot<'a> => unit) => unit,
}
@module("firebase/firestore")
external getDocs: query<'a> => promise<querySnapshot<'a>> = "getDocs"

@module("firebase/firestore")
external getDocFromCache: documentReference<'a> => promise<documentSnapshot<'a>> = "getDocFromCache"

type setOptions = {merge?: bool, mergeFields?: array<string>}

type dataConverter<'a, 'b> = {
  fromFirestore: (. documentSnapshot<'a>, snapshotOptions) => 'b,
  toFirestore: (. 'b, setOptions) => 'a,
}

@send
external withConterterCollection: (
  collectionReference<'a>,
  dataConverter<'a, 'b>,
) => collectionReference<'b> = "withConverter"

@send
external withConterterDoc: (documentReference<'a>, dataConverter<'a, 'b>) => documentReference<'b> =
  "withConverter"

@module("firebase/firestore")
external setDoc: (documentReference<'a>, 'a) => promise<unit> = "setDoc"

// Beware that updateDoc does not invoke the converter
@module("firebase/firestore")
external updateDoc: (documentReference<'a>, {..}) => promise<unit> = "updateDoc"

@module("firebase/firestore")
external addDoc: (collectionReference<'a>, 'a) => promise<documentReference<'a>> = "addDoc"

@module("firebase/firestore")
external where: (
  string,
  [#"<" | #"<=" | #"==" | #"!=" | #">=" | #">" | #array_contains | #"in"],
  'a,
) => queryConstraint = "where"

type aggregateSpecData = {count: int}
type aggregateQuerySnapshot = {data: (. unit) => aggregateSpecData}
@module("firebase/firestore")
external getCountFromServer: collectionReference<'a> => promise<aggregateQuerySnapshot> =
  "getCountFromServer"

module Transaction = {
  type t
  @send
  external delete: (t, documentReference<'a>) => unit = "delete"
  @send
  external get: (t, documentReference<'a>) => promise<documentSnapshot<'a>> = "get"
  @send
  external set: (t, documentReference<'a>, 'a, setOptions) => unit = "set"
  @send
  external update: (t, documentReference<'a>, {..}) => unit = "update"
}

@module("firebase/firestore")
external runTransaction: (. firestore, Transaction.t => promise<'a>) => promise<'a> =
  "runTransaction"

module WriteBatch = {
  type t
  @send
  external delete: (t, documentReference<'a>) => t = "delete"
  @send
  external set: (t, documentReference<'a>, 'a, setOptions) => t = "set"
  @send
  external update: (t, documentReference<'a>, {..}) => t = "update"
  @send
  external commit: t => promise<unit> = "commit"
}

@module("firebase/firestore")
external writeBatch: firestore => WriteBatch.t = "writeBatch"

type reactfireOptions<'a> = {
  idField?: string,
  initialData?: 'a,
  suspense?: bool,
}

@module("reactfire")
external useFirestoreDocData: (
  . documentReference<'a>,
  option<reactfireOptions<'a>>,
) => observableStatus<'a> = "useFirestoreDocData"

@module("reactfire")
external useFirestoreCollectionData: (
  . query<'a>,
  reactfireOptions<'a>,
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

module FirestoreLocalCache = {
  type t

  module PersistentTabManager = {
    type t

    @module("firebase/firestore")
    external persistentSingleTabManager: (. unit) => t = "persistentLocalCache"

    @module("firebase/firestore")
    external persistentMultipleTabManager: (. unit) => t = "persistentMultipleTabManager"
  }

  type persistentCacheSettings = {
    cacheSizeBytes?: int,
    tabManager?: PersistentTabManager.t,
  }

  @module("firebase/firestore")
  external cacheSizeUnlimited: int = "CACHE_SIZE_UNLIMITED"

  @module("firebase/firestore")
  external persistentLocalCache: persistentCacheSettings => t = "persistentLocalCache"
}

type firestoreSettings = {localCache: FirestoreLocalCache.t}
@module("firebase/firestore")
external initializeFirestore: (FirebaseApp.t, firestoreSettings) => firestore =
  "initializeFirestore"

module AppCheckProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: appCheck, ~children: React.element) => React.element = "AppCheckProvider"
}

module Timestamp = {
  @genType.import("firebase/firestore") @genType.as("Timestamp")
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
  @module("firebase/firestore") @scope("Timestamp")
  external now: unit => t = "now"
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
external collectionRx: (
  query<'a>,
  reactfireOptions<'a>,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, array<querySnapshot<'a>>> = "collection"

@module("rxfire/firestore")
external collectionDataRx: (
  query<'a>,
  reactfireOptions<'a>,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, array<'a>> = "collectionData"

@module("rxfire/firestore")
external docRx: documentReference<'a> => Rxjs.t<Rxjs.foreign, Rxjs.void, documentSnapshot<'a>> =
  "doc"

@module("rxfire/firestore")
external snapToData: (documentSnapshot<'a>, reactfireOptions<'a>) => 'a = "snapToData"

@module("rxfire/firestore")
external docDataRx: (
  documentReference<'a>,
  reactfireOptions<'a>,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'a> = "docData"

type authProvider

module FederatedAuthProvider = {
  type t
  @new @module("firebase/auth")
  external googleAuthProvider: unit => t = "GoogleAuthProvider"
}

@module("firebase/auth")
external googleAuthProvider: authProvider = "GoogleAuthProvider"

type userCredential = {
  user: User.t,
  providerId: Js.Nullable.t<string>,
  operationType: @string [#link | #reauthenticate | #signIn],
}

@module("firebase/auth")
external signInWithPopup: (Auth.t, FederatedAuthProvider.t) => promise<userCredential> =
  "signInWithPopup"

@module("firebase/firestore")
external connectFirestoreEmulator: (. firestore, string, int) => unit = "connectFirestoreEmulator"

@module("firebase/auth")
external connectAuthEmulator: (. Auth.t, string) => unit = "connectFirestoreEmulator"
