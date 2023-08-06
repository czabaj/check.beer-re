type classesType = {root: string}

@module("./UnauthenticatedTemplate.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~className=?) => {
  <div
    className={`${Styles.page.centered} ${classes.root} ${className->Option.getWithDefault("")}`}>
    <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
    {children}
  </div>
}
