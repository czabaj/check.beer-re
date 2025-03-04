module FirebaseOptions = {
  type t
}

module FirebaseApp = {
  type t = {options: FirebaseOptions.t}
}

module Analytics = {
  type t

  type eventName = @string
  [
    | #add_payment_info
    | #add_shipping_info
    | #add_to_cart
    | #add_to_wishlist
    | #begin_checkout
    | #checkout_progress
    | #"exception"
    | #generate_lead
    | #login
    | #page_view
    | #purchase
    | #refund
    | #remove_from_cart
    | #screen_view
    | #search
    | #select_content
    | #select_item
    | #select_promotion
    | #set_checkout_option
    | #share
    | #sign_up
    | #timing_complete
    | #view_cart
    | #view_item
    | #view_item_list
    | #view_promotion
    | #view_search_results
  ]

  type eventParams = {
    checkout_option?: string,
    checkout_step?: int,
    item_id?: string,
    content_type?: string,
    coupon?: string,
    currency?: string,
    description?: string,
    fatal?: bool,
    // items?: Item[],
    method?: string,
    number?: string,
    // promotions?: Promotion[],
    screen_name?: string,
    /**
     * Firebase-specific. Use to log a `screen_name` to Firebase Analytics.
     */
    firebase_screen?: string,
    /**
     * Firebase-specific. Use to log a `screen_class` to Firebase Analytics.
     */
    firebase_screen_class?: string,
    search_term?: string,
    // shipping?: Currency,
    // tax?: Currency,
    transaction_id?: string,
    value?: float,
    event_label?: string,
    event_category?: string,
    shipping_tier?: string,
    item_list_id?: string,
    item_list_name?: string,
    promotion_id?: string,
    promotion_name?: string,
    payment_type?: string,
    affiliation?: string,
    page_title?: string,
    page_location?: string,
    page_path?: string,
  }

  @module("firebase/analytics")
  external getAnalytics: FirebaseApp.t => t = "getAnalytics"

  @module("firebase/analytics")
  external logEvent: (t, eventName, eventParams) => unit = "logEvent"
}

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

@module("firebase/firestore")
external enableIndexedDbPersistence: firestore => promise<unit> = "enableIndexedDbPersistence"

@module("firebase/firestore")
external enableMultiTabIndexedDbPersistence: firestore => promise<unit> =
  "enableMultiTabIndexedDbPersistence"

@module("firebase/firestore") @variadic
external arrayUnion: array<'a> => {..} = "arrayUnion"

@module("firebase/firestore")
external incrementInt: int => {..} = "increment"

@genType.import("firebase/firestore") @genType.as("DocumentReference")
type rec documentReference<'a> = {id: string, parent: option<collectionReference<'a>>, path: string}
@genType.import("firebase/firestore") @genType.as("CollectionReference") and collectionReference<'a>

@module("firebase/firestore")
external doc: (firestore, ~path: string) => documentReference<'a> = "doc"

@module("firebase/firestore")
external collection: (firestore, ~path: string) => collectionReference<'a> = "collection"

@module("firebase/firestore")
external seedDoc: collectionReference<'a> => documentReference<'a> = "doc"

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

type documentSnapshot<'a> = {
  data: snapshotOptions => 'a,
  exists: unit => bool,
  get: (~fieldPath: string, ~options: snapshotOptions) => unknown,
  id: string,
  ref: documentReference<'a>,
}
@module("firebase/firestore")
external getDoc: documentReference<'a> => promise<documentSnapshot<'a>> = "getDoc"

type querySnapshot<'a> = {
  docs: array<documentSnapshot<'a>>,
  forEach: (documentSnapshot<'a> => unit) => unit,
}
@module("firebase/firestore")
external getDocs: query<'a> => promise<querySnapshot<'a>> = "getDocs"

@module("firebase/firestore")
external getDocFromCache: documentReference<'a> => promise<documentSnapshot<'a>> = "getDocFromCache"

type setOptions = {merge?: bool, mergeFields?: array<string>}

type dataConverter<'a, 'b> = {
  fromFirestore: (documentSnapshot<'a>, snapshotOptions) => 'b,
  toFirestore: ('b, setOptions) => 'a,
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
type aggregateQuerySnapshot = {data: unit => aggregateSpecData}
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
external runTransaction: (firestore, Transaction.t => promise<'a>) => promise<'a> = "runTransaction"

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

module User = {
  type userInfo = {
    displayName: Js.null<string>,
    email: Js.null<string>,
    phoneNumber: Js.null<string>,
    photoURL: Js.null<string>,
    providerId: string,
    uid: string,
  }
  type metadata = {
    // timestamp in a string
    createdAt: string,
    // datetime in format e.g. "Fri, 14 Jul 2023 11:48:18 GMT"
    creationTime: string,
    // timestamp in a string
    lastLoginAt: string,
    // datetime in format e.g. "Fri, 14 Jul 2023 11:48:18 GMT"
    lastSignInTime: string,
  }
  type t = {
    displayName: Js.null<string>,
    email: Js.null<string>,
    emailVerified: bool,
    isAnonymous: bool,
    metadata: metadata,
    photoURL: Js.null<string>,
    providerData: array<userInfo>,
    uid: string,
  }

  @send
  external reload: t => promise<unit> = "reload"
}

module Auth = {
  type t = {
    app: FirebaseApp.t,
    currentUser: Js.null<User.t>,
    name: string,
  }

  @set external setLanguageCode: (t, string) => unit = "languageCode"
  @send external useDeviceLanguage: t => unit = "useDeviceLanguage"

  type authCredential

  @string
  type operationType = [#link | #reauthenticate | #signIn]

  type userCredential = {
    operationType: operationType,
    providerId: Js.null<string>,
    user: User.t,
  }

  @send
  external onAuthStateChanged: (t, 'user) => 'unsubscribe = "onAuthStateChanged"

  @module("firebase/auth")
  external signOut: t => promise<unit> = "signOut"

  type updateProfileData = {displayName?: string, photoURL?: string}
  @module("firebase/auth")
  external updateProfile: (User.t, updateProfileData) => promise<unit> = "updateProfile"

  module EmailAuthProvider = {
    let providerID = "password"

    @val @module("firebase/auth") @scope("EmailAuthProvider")
    external credential: (~email: string, ~password: string) => authCredential = "credential"
  }
  module GithubAuthProvider = {
    let providerID = "github.com"
  }
  module GoogleAuthProvider = {
    let providerID = "google.com"
  }

  type actionCodeSettings = {
    url: string,
    handleCodeInApp: bool,
  }

  @module("firebase/auth")
  external sendSignInLinkToEmail: (
    t,
    ~email: string,
    ~actionCodeSettings: actionCodeSettings,
  ) => promise<unit> = "sendSignInLinkToEmail"

  @module("firebase/auth")
  external isSignInWithEmailLink: (t, ~href: string) => bool = "isSignInWithEmailLink"

  @module("firebase/auth")
  external signInWithEmailLink: (t, ~email: string, ~href: string) => promise<userCredential> =
    "signInWithEmailLink"

  @module("firebase/auth")
  external createUserWithEmailAndPassword: (
    t,
    ~email: string,
    ~password: string,
  ) => promise<userCredential> = "createUserWithEmailAndPassword"

  @module("firebase/auth")
  external getAuth: FirebaseApp.t => t = "getAuth"

  module FederatedAuthProvider = {
    type t
    @new @module("firebase/auth")
    external googleAuthProvider: unit => t = "GoogleAuthProvider"
  }

  @module("firebase/auth")
  external reauthenticateWithCredential: (User.t, authCredential) => promise<userCredential> =
    "reauthenticateWithCredential"

  @module("firebase/auth")
  external sendPasswordResetEmail: (t, ~email: string) => promise<unit> = "sendPasswordResetEmail"

  @module("firebase/auth")
  external signInWithEmailAndPassword: (
    t,
    ~email: string,
    ~password: string,
  ) => promise<userCredential> = "signInWithEmailAndPassword"

  @module("firebase/auth")
  external signInWithPopup: (t, FederatedAuthProvider.t) => promise<userCredential> =
    "signInWithPopup"

  @module("firebase/auth")
  external signInWithRedirect: (t, FederatedAuthProvider.t) => promise<userCredential> =
    "signInWithRedirect"

  @module("firebase/auth")
  external connectAuthEmulator: (t, string) => unit = "connectAuthEmulator"

  @module("firebase/auth")
  external updatePassword: (User.t, ~newPassword: string) => promise<unit> = "updatePassword"
}

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
    external persistentSingleTabManager: unit => t = "persistentLocalCache"

    @module("firebase/firestore")
    external persistentMultipleTabManager: unit => t = "persistentMultipleTabManager"
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

type firestoreSettings = {localCache?: FirestoreLocalCache.t}
@module("firebase/firestore")
external initializeFirestore: (FirebaseApp.t, firestoreSettings) => firestore =
  "initializeFirestore"

module AppCheckProvider = {
  @react.component @module("reactfire")
  external make: (~sdk: appCheck, ~children: React.element) => React.element = "AppCheckProvider"
}

module Messaging = {
  type t

  @module("firebase/messaging")
  external getMessaging: FirebaseApp.t => t = "getMessaging"

  type getTokenOptions = {
    serviceWorkerRegistration?: ServiceWorker.serviceWorkerRegistration,
    vapidKey: string,
  }

  // Subscribes the Messaging instance to push notifications. Returns a Firebase Cloud Messaging registration token that
  // can be used to send push messages to that Messaging instance. If notification permission isn't already granted,
  // this method asks the user for permission. The returned promise rejects if the user does not allow the app to show
  // notifications.
  @module("firebase/messaging")
  external _getToken: (t, getTokenOptions) => promise<string> = "getToken"

  let getToken = async (messaging: t) => {
    let serviceWorkerRegistration = await ServiceWorker.serviceWorkerRegistration
    await _getToken(
      messaging,
      {serviceWorkerRegistration, vapidKey: %raw(`import.meta.env.VITE_FIREBASE_VAPID_KEY`)},
    )
  }

  type fcmOptions = {
    analyticsLabel?: string,
    link?: string,
  }

  type messagePayload = {
    collapseKey: string,
    data: Js.Dict.t<string>,
    fcmOptions: fcmOptions,
    from: string,
    messageId: string,
    notification: Js.Dict.t<string>,
  }

  @module("firebase/messaging")
  external onMessage: (t, messagePayload => unit) => unit => unit = "onMessage"
}

module Timestamp = {
  @genType.import("firebase/firestore") @genType.as("Timestamp")
  type t = {seconds: float, nanoseconds: int}
  @new @module("firebase/firestore")
  external make: (~seconds: float, ~nanoseconds: float) => t = "Timestamp"
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

module Functions = {
  type t

  // we are currently using just these two, but more can be added if needed
  // @see https://firebase.google.com/docs/functions/locations
  type functionLocation = [#"europe-central2" | #"europe-west3"]

  @module("firebase/functions")
  external getFunctions: FirebaseApp.t => t = "getFunctions"

  @module("firebase/functions")
  external getFunctionsInRegion: (FirebaseApp.t, functionLocation) => t = "getFunctions"

  type callResult<'a> = {data: 'a}
  @module("firebase/functions")
  external httpsCallable: (t, string) => 'a => promise<callResult<'b>> = "httpsCallable"
}

@module("firebase/firestore")
external connectFirestoreEmulator: (firestore, string, int) => unit = "connectFirestoreEmulator"
