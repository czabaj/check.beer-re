@react.component
let make = (~children, ~className=?, ~formId, ~heading, ~onDismiss, ~visible) => {
  <Dialog ?className visible>
    <header>
      <h3> {React.string(heading)} </h3>
    </header>
    {children}
    <footer>
      <button
        className={Styles.button.variantPrimary}
        form={formId}
        type_="submit">
        {React.string("Uložit")}
      </button>
      <button
        className={Styles.button.base} type_="button" onClick={_ => onDismiss()}>
        {React.string("Zrušit")}
      </button>
    </footer>
  </Dialog>
}
