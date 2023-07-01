type classesType = {root: string}
@module("./SectionWithHeader.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~buttonsSlot, ~headerId, ~headerSlot) => {
  <section ariaLabelledby=headerId className={classes.root}>
    <header>
      <h3 id={headerId}> {headerSlot} </h3>
      {buttonsSlot}
    </header>
    <div className={Styles.boxClasses.base}> {children} </div>
  </section>
}
