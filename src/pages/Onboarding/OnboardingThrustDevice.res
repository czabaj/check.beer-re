@genType @react.component
let make = (~onSkip, ~onThrust, ~mentionWebAuthn) => {
  <OnboardingTemplate>
    <h2> {React.string("Ukládání dat")} </h2>
    <p className={Styles.fieldset.gridSpan}>
      {React.string(`Aplikace umí pracovat i bez internetu`)}
      {!mentionWebAuthn
        ? React.string(`.`)
        : React.string(` nebo přihlašování bez hesla, například otiskem prstu nebo obličejem.`)}
      {React.string(` K tomu potřebuje ukládat data do zařízení.`)}
    </p>
    <p>
      {React.string(
        "Pokud serfuješ na cizím počítači a nechceš aby se k datům dostal někdo cizí, tento krok přeskoč.",
      )}
    </p>
    <button className={Styles.button.base} onClick={_ => onThrust()} type_="button">
      {React.string(`Tomuto zařízení důvěřuji`)}
    </button>
    <button className={Styles.link.base} onClick={_ => onSkip()} type_="button">
      {React.string(`Na tomto zařízení nechci ukládat svá data`)}
    </button>
  </OnboardingTemplate>
}
