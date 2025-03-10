type classesType = {popover: string}
@module("./ButtonMenu.module.css") external classes: classesType = "default"

type menuItem = {
  disabled?: bool,
  label: string,
  onClick: ReactEvent.Mouse.t => unit,
}

@genType @react.component
let make = (~children, ~className=?, ~menuItems, ~title=?) => {
  let nodeId = React.useId()->String.slice(~start=1, ~end=-1)
  let popoverId = `popover-${nodeId}`
  let anchorId = `anchor-${nodeId}`
  let anchorName = `--button-menu-${nodeId}`
  React.useEffect0(() => {
    OddbirdCssAnchorPositioning.polyfillDebounced()
    None
  })
  <>
    {React.cloneElement(
      <button
        ?className
        id=anchorId
        style={ReactDOM.Style.make()->ReactDOM.Style.unsafeAddProp("anchorName", anchorName)}
        ?title
        type_="button">
        {children}
      </button>,
      {
        "popovertarget": popoverId,
        "popovertargetaction": "toggle",
      },
    )}
    {React.cloneElement(
      <div
        className={classes.popover}
        id={popoverId}
        style={ReactDOM.Style.make()->ReactDOM.Style.unsafeAddProp("positionAnchor", anchorName)}>
        <nav>
          <ul>
            {menuItems
            ->Array.mapWithIndex((item, idx) =>
              <li key={idx->Int.toString}>
                <button
                  disabled={item.disabled->Option.getOr(false)} onClick=item.onClick type_="button">
                  {React.string(item.label)}
                </button>
              </li>
            )
            ->React.array}
          </ul>
        </nav>
      </div>,
      {
        "anchor": anchorId,
        "popover": "",
      },
    )}
  </>
}
