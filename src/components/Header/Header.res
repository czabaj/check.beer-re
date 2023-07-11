type classesType = {buttonLeft: string, buttonRight: string, root: string}

@module("./Header.module.css") external classes: classesType = "default"

@react.component
let make = (~buttonLeftSlot, ~buttonRightSlot, ~className=?, ~headingSlot, ~subheadingSlot) => {
  <header className={`${classes.root} ${className->Option.getWithDefault("")}`}>
    <h2> {headingSlot} </h2>
    <p> {subheadingSlot} </p>
    {buttonLeftSlot}
    {buttonRightSlot}
  </header>
}
