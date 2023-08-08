let isFirebaseError = exn => Exn.name(exn) === Some("FirebaseError")

exception EmailChangeNeedsVerification
exception EmailExists
exception InvalidPassword
exception NeedConfirmation
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
        | Some("auth/email-change-needs-verification") => EmailChangeNeedsVerification
        | Some("auth/email-already-in-use") => EmailExists
        | Some("auth/wrong-password") => InvalidPassword
        | Some("auth/account-exists-with-different-credential") => NeedConfirmation
        | Some("auth/unverified-email") => UnverifiedEmail
        | Some("auth/weak-password") => WeakPassword
        | _ => exn
        }
  | _ => exn
  }
}
