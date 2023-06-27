@react.component
let make = () => {
  let auth = Firebase.useAuth()
  <div>
    <h2> {React.string("Sign in")} </h2>
    <button
      onClick={_ => {
        Firebase.signInWithPopup(auth, Firebase.googleAuthProvider)->ignore
      }}
      type_="button">
      {React.string("Sign in with Google")}
    </button>
  </div>
}
