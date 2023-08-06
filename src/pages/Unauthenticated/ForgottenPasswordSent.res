@genType @react.component
let make = (~email, ~onGoBack) => {
  <UnauthenticatedTemplate>
    <h2> {React.string("Zapomenuté heslo")} </h2>
    <p>
      {React.string(`Poslali jsme vám odkaz na změnu hesla. Zkontrolujte poštu na adrese `)}
      <b> {React.string(email)} </b>
    </p>
    <button className={Styles.button.base} onClick={_ => onGoBack()} type_="button">
      {React.string(`Zpět na přihlášení`)}
    </button>
  </UnauthenticatedTemplate>
}
