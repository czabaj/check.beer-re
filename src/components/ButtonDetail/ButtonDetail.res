type classesType = {root: string}
@module("./ButtonDetail.module.css") external classes: classesType = "default"

@react.component
let make = (~className=?, ~onClick, ~title) => {
  <button
    className={`${classes.root} ${className->Option.getWithDefault("")}`}
    title
    type_="button"
    onClick={onClick}>
    {React.string("👀")}
  </button>
}
