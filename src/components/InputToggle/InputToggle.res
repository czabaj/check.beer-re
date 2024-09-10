type classesType = {inputToggle: string}
@module("./InputToggle.module.css") external classes: classesType = "default"

@genType @react.component
let make = (~ariaDescribedby=?, ~ariaInvalid=?, ~checked, ~id=?, ~name=?, ~onChange) => {
  <input
    ?ariaDescribedby
    ?ariaInvalid
    className={`${classes.inputToggle}`}
    checked
    ?id
    ?name
    type_="checkbox"
    onChange
    role="switch"
  />
}
