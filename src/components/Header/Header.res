type classesType = {buttonLeft: string, buttonRight: string, root: string}

@module("./Header.module.css") external classes: classesType = "default"

@react.component
let make = (~buttonLeftSlot, ~buttonRightSlot, ~className=?, ~headingSlot, ~subheadingSlot) => {
  let headerRef = React.useRef(Nullable.null)
  let layout = Hooks.useIsHorizontallyOverflowing(headerRef.current, [`xl`, `sm`])
  React.cloneElement(
    <header
      className={`${classes.root} ${className->Option.getOr("")}`}
      ref={headerRef->ReactDOM.Ref.domRef}>
      <h2> {headingSlot} </h2>
      <p> {subheadingSlot} </p>
      {buttonLeftSlot}
      {buttonRightSlot}
    </header>,
    {"data-layout": layout},
  )
}
