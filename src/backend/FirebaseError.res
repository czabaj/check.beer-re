let isFirebaseError = exn => Exn.name(exn) === Some("FirebaseError")

exception EmailChangeNeedsVerification
exception EmailExists
exception InvalidPassword
exception NeedConfirmation
exception TooManyRequests
exception UnverifiedEmail
exception WeakPassword

let toFirebaseError = exn => {
  switch exn {
  | Exn.Error(obj) =>
    !isFirebaseError(obj)
      ? exn
        // This is just a very small subset of all possible errors
        //@see https://firebase.google.com/docs/reference/js/auth#autherrorcodes
      : switch ErrorUtils.code(obj) {
        | Some("auth/account-exists-with-different-credential") => NeedConfirmation
        | Some("auth/email-already-in-use") => EmailExists
        | Some("auth/email-change-needs-verification") => EmailChangeNeedsVerification
        | Some("auth/too-many-requests") => TooManyRequests
        | Some("auth/unverified-email") => UnverifiedEmail
        | Some("auth/weak-password") => WeakPassword
        | Some("auth/wrong-password") => InvalidPassword
        | _ => exn
        }
  | _ => exn
  }
}
