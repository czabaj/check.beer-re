type classesType = {root: string}

@module("./DialogCycling.module.css") external classes: classesType = "default"

@react.component
let make = (
  ~children,
  ~className=?,
  ~footerSlot=?,
  ~hasNext,
  ~hasPrevious,
  ~header,
  ~onDismiss,
  ~onNext,
  ~onPrevious,
  ~visible,
) => {
  <Dialog className={`${classes.root} ${className->Option.getWithDefault("")}`} visible>
    <header>
      <h3> {React.string(header)} </h3>
      <button
        className={`${Styles.button.base}`}
        disabled={!hasPrevious}
        onClick={_ => onPrevious()}
        type_="button">
        {React.string("⬅️ Předchozí")}
      </button>
      <button
        className={`${Styles.button.base}`}
        disabled={!hasNext}
        onClick={_ => onNext()}
        type_="button">
        {React.string("Následující ➡️")}
      </button>
    </header>
    <Dialog.DialogBody> {children} </Dialog.DialogBody>
    <footer>
      <button className={`${Styles.button.base}`} onClick={_ => onDismiss()}>
        {React.string("Zavřít")}
      </button>
      {footerSlot->Option.getWithDefault(React.null)}
    </footer>
  </Dialog>
}
