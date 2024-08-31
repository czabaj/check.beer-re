type classesType = {emptyMessage: string, root: string}
@module("./SectionWithHeader.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~buttonsSlot, ~className=?, ~headerId, ~headerSlot) => {
  <section ariaLabelledby=headerId className={`${classes.root} ${className->Option.getOr("")}`}>
    <header>
      <h3 id={headerId}> {headerSlot} </h3>
      {buttonsSlot}
    </header>
    <div className={Styles.box.base}> {children} </div>
  </section>
}
