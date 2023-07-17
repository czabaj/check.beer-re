type classesType = {deleteConfirmation: string}

@module("./DialogConfirmation.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~className=?, ~heading, ~onConfirm, ~onDismiss, ~visible) => {
  <Dialog ?className visible>
    <header>
      <h3> {React.string(heading)} </h3>
    </header>
    {children}
    <footer>
      <button
        className={`${Styles.button.base} ${Styles.button.variantPrimary}`}
        onClick={_ => onConfirm()}
        type_="submit">
        {React.string("Provést")}
      </button>
      <button
        className={`${Styles.button.base}`} type_="button" onClick={_ => onDismiss()}>
        {React.string("Zrušit")}
      </button>
    </footer>
  </Dialog>
}
