type classesType = {root: string}

@module("./OnboardingTemplate.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~loadingOverlay=?) => {
  <div
    ariaHidden=?loadingOverlay
    className={`${Styles.page.centered} ${classes.root}`}>
    <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
    {children}
  </div>
}
