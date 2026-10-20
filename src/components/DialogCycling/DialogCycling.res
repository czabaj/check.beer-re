type classesType = {heading: string, root: string}

@module("./DialogCycling.module.css") external classes: classesType = "default"

@react.component
let make = (
  ~children,
  ~className=?,
  ~hasNext,
  ~hasPrevious,
  ~header,
  ~headerSlot=?,
  ~onDismiss,
  ~onNext,
  ~onPrevious,
  ~visible,
) => {
  <Dialog className={`${classes.root} ${className->Option.getOr("")}`} visible>
    <header>
      <div className={classes.heading}>
        <h3> {React.string(header)} </h3>
        {headerSlot->Option.getOr(React.null)}
      </div>
      <button
        className={Styles.button.iconOnly}
        onClick={_ => onDismiss()}
        title="Zavřít dialog">
        {React.string("✖️")}
      </button>
    </header>
    <Dialog.DialogBody> {children} </Dialog.DialogBody>
    <footer>
      <button
        className={Styles.button.base}
        disabled={!hasPrevious}
        onClick={_ => onPrevious()}
        type_="button">
        {React.string("⬅️ Předchozí")}
      </button>
      <button
        className={Styles.button.base}
        disabled={!hasNext}
        onClick={_ => onNext()}
        type_="button">
        {React.string("Následující ➡️")}
      </button>
    </footer>
  </Dialog>
}
