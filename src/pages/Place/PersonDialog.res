type classesType = {root: string}

@module("./PersonDialog.module.css") external classes: classesType = "default"

@react.component
let make = (~personName, ~usedTap, ~onDismiss) => {
  <Dialog className={classes.root} visible={true}>
    <header>
      <h3> {React.string(personName)} </h3>
      <button
        className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.iconOnly}`}
        onClick={onDismiss}
        type_="button">
        {React.string("X")}
      </button>
    </header>
    <form
      onChange={event => {
        let formElements = event->ReactEvent_V3.Form.currentTarget
        Js.log(formElements)
      }}>
      <div> {React.string(`Vybraná pípa: ${usedTap}`)} </div>
      <fieldset>
        <legend> {React.string("Přidat konzumaci")} </legend>
        <label>
          <input name="consumption" type_="radio" value="500" />
          <span> {React.string("Velké")} </span>
        </label>
        <label>
          <input name="consumption" type_="radio" value="300" />
          <span> {React.string("Malé")} </span>
        </label>
      </fieldset>
    </form>
  </Dialog>
}
