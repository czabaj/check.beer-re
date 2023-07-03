@react.component
let make = (~children, ~className=?, ~header, ~onDismiss, ~onNext, ~onPrevious, ~visible) => {
  <Dialog ?className visible>
    <header>
      <h3> {React.string(header)} </h3>
      <button
        className={`${Styles.buttonClasses.button}`} onClick={_ => onPrevious()} type_="button">
        {React.string("⬅️ Předchozí")}
      </button>
      <button className={`${Styles.buttonClasses.button}`} onClick={_ => onNext()} type_="button">
        {React.string("Následující ➡️")}
      </button>
    </header>
    <Dialog.DialogBody> {children} </Dialog.DialogBody>
    <footer>
      <button className={`${Styles.buttonClasses.button}`} onClick={_ => onDismiss()}>
        {React.string("Zavřít")}
      </button>
    </footer>
  </Dialog>
}
