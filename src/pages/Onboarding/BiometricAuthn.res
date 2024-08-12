@genType @react.component
let make = (~loadingOverlay, ~onSetupAuthn, ~onSkip, ~setupError=?) => {
  <OnboardingTemplate loadingOverlay>
    <h2> {React.string("Přihlášení bez hesla")} </h2>
    <p> {React.string(`Tvoje zařízení umožňuje přihlásit se bez hesla.`)} </p>
    {setupError->Option.mapOr(React.null, _ => {
      <p className={Styles.messageBar.variantDanger}>
        {React.string("Nastavení se nezdařilo. Zkus to znovu nebo tento krok přeskoč.")}
      </p>
    })}
    <button className={Styles.button.base} onClick={_ => onSetupAuthn()} type_="button">
      {React.string(`Nastavit`)}
    </button>
    <button className={Styles.link.base} onClick={_ => onSkip()} type_="button">
      {React.string(`Přeskočit`)}
    </button>
  </OnboardingTemplate>
}
