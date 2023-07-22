type classesType = {root: string}
@module("./InputToggle.module.css") external classes: classesType = "default"

@react.component
let make = (~\"aria-describedby"=?, ~\"aria-invalid"=?, ~checked, ~id=?, ~name=?, ~onChange) => {
  <div className=classes.root>
    {React.cloneElement(
      <input checked ?id ?name type_="checkbox" onChange />,
      {
        "aria-describedby": \"aria-describedby",
        "aria-invalid": \"aria-invalid",
      },
    )}
    <div />
  </div>
}
