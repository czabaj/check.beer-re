type classesType = {popover: string}
@module("./ButtonMenu.module.css") external classes: classesType = "default"

type menuItem = {
  disabled?: bool,
  label: string,
  onClick: ReactEvent.Mouse.t => unit,
}

@genType @react.component
let make = (~children, ~className=?, ~menuItems, ~title=?) => {
  let popoverId = React.useId()
  let anchorId = React.useId()
  <>
    {React.cloneElement(
      <button ?className id=anchorId ?title type_="button"> {children} </button>,
      {
        "popovertarget": popoverId,
        "popovertargetaction": "toggle",
      },
    )}
    {React.cloneElement(
      <div className={classes.popover} id={popoverId}>
        <nav>
          <ul>
            {menuItems
            ->Array.mapWithIndex((item, idx) =>
              <li key={idx->Int.toString}>
                <button
                  disabled={item.disabled->Option.getWithDefault(false)}
                  onClick=item.onClick
                  type_="button">
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
