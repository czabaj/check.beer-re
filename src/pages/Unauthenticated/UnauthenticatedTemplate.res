type classesType = {root: string}

@module("./UnauthenticatedTemplate.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~className=?, ~isOnline=?, ~loadingOverlay=?) => {
  <div
    ariaHidden=?loadingOverlay
    className={`${Styles.page.centered} ${classes.root} ${className->Option.getWithDefault("")}`}>
    <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
    {isOnline !== Some(false)
      ? React.null
      : <p className={Styles.messageBar.variantDanger}>
          {React.string(
            "Vypadá to že jsme bez internetu. Přihlášení ani registrace asi nepůjde.",
          )}
        </p>}
    {children}
  </div>
}
