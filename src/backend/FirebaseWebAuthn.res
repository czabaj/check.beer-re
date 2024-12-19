@module("@firebase-web-authn/browser")
external createUserWithPasskey: (
  Firebase.Auth.t,
  Firebase.Functions.t,
  string,
) => promise<Firebase.Auth.userCredential> = "createUserWithPasskey"

@module("@firebase-web-authn/browser")
external linkWithPasskey: (
  Firebase.Auth.t,
  Firebase.Functions.t,
  string,
) => promise<Firebase.Auth.userCredential> = "linkWithPasskey"


@module("@firebase-web-authn/browser")
external signInWithPasskey: (
  Firebase.Auth.t,
  Firebase.Functions.t,
) => promise<Firebase.Auth.userCredential> = "signInWithPasskey"

@module("@firebase-web-authn/browser")
external unlinkPasskey: (Firebase.Auth.t, Firebase.Functions.t, string) => promise<unit> =
  "unlinkPasskey"

@module("@firebase-web-authn/browser")
external verifyUserWithPasskey: (
  Firebase.Auth.t,
  Firebase.Functions.t,
) => promise<Firebase.Auth.userCredential> = "verifyUserWithPasskey"

exception CancelledByUser
exception InvalidFunctionResponse
exception NoOperationNeeded

let toFirebaseWebAuthnError = exn => {
  switch exn {
  | Exn.Error(obj) =>
    switch ErrorUtils.code(obj) {
    | Some("firebaseWebAuthn/cancelled") => CancelledByUser
    | Some("firebaseWebAuthn/invalid") => InvalidFunctionResponse
    | Some("firebaseWebAuthn/no-op") => NoOperationNeeded
    | _ => exn
    }
  | _ => exn
  }
}
