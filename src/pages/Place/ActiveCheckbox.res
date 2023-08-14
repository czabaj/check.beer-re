type classesType = {root: string}

@module("./ActiveCheckbox.module.css") external classes: classesType = "default"

@react.component
let make = (~changes: Belt.Map.String.t<bool>, ~initialActive, ~personId, ~setChanges) => {
  let checked = changes->Belt.Map.String.getWithDefault(personId, initialActive)
  <label className={`${classes.root} ${Styles.utility.breakout}`}>
    {React.string("Zde")}
    <input
      checked={checked}
      type_="checkbox"
      onChange={_ => {
        let newChecked = !checked
        let newChanges =
          initialActive === newChecked
            ? changes->Belt.Map.String.remove(personId)
            : changes->Belt.Map.String.set(personId, newChecked)
        setChanges(_ => Some(newChanges))
      }}
    />
  </label>
}
