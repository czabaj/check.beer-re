@react.component
let make = (~children, ~heading, ~onConfirm, ~onDismiss, ~visible) => {
  <Dialog visible>
    <header>
      <h3> {React.string(heading)} </h3>
    </header>
    {children}
    <footer>
      <button
        className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.variantPrimary}`}
        onClick={_ => onConfirm()}
        type_="submit">
        {React.string("Provést")}
      </button>
      <button
        className={`${Styles.buttonClasses.button}`} type_="button" onClick={_ => onDismiss()}>
        {React.string("Zrušit")}
      </button>
    </footer>
  </Dialog>
}
