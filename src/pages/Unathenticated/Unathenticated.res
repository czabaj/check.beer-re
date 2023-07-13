@react.component
let make = () => {
  let auth = Firebase.useAuth()
  <div className={Styles.page.centered}>
    <h2> {React.string("Přihlášení")} </h2>
    <button
      className={Styles.button.button}
      onClick={_ => {
        Firebase.signInWithPopup(auth, Firebase.FederatedAuthProvider.googleAuthProvider())
        ->Promise.catch(error => {
          Js.log(error)
          Promise.reject(error)
        })
        ->ignore
      }}
      type_="button">
      {React.string("Přihlásit se přes Google")}
    </button>
  </div>
}
