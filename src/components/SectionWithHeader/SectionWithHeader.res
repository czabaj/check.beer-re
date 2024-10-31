type classesType = {emptyMessage: string, root: string}
@module("./SectionWithHeader.module.css") external classes: classesType = "default"

@react.component
let make = (~children, ~buttonsSlot, ~className=?, ~headerId, ~headerSlot, ~noBackground=?) => {
  <section ariaLabelledby=headerId className={`${classes.root} ${className->Option.getOr("")}`}>
    <header>
      <h3 id={headerId}> {headerSlot} </h3>
      {buttonsSlot}
    </header>
    <div className={noBackground->Option.getOr(false) ? "" : Styles.box.base}> {children} </div>
  </section>
}
