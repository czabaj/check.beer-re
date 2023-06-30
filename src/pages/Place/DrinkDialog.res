type classesType = {root: string}

@module("./DrinkDialog.module.css") external classes: classesType = "default"

type selectOption = {text: string, value: string}

@react.component
let make = (
  ~personName,
  ~preferredTap,
  ~onDismiss,
  ~tapsWithKegs: Belt.Map.String.t<Db.kegConverted>,
) => {
  let tapsEmpty = tapsWithKegs->Belt.Map.String.isEmpty
  <Dialog className={classes.root} onClickOutside={onDismiss} visible={true}>
    <header>
      <h3> {React.string(personName)} </h3>
      <button
        className={`${Styles.buttonClasses.button} ${Styles.buttonClasses.iconOnly}`}
        onClick={_ => onDismiss()}
        type_="button">
        {React.string("X")}
      </button>
    </header>
    <form
      onChange={event => {
        let formElements = event->ReactEvent_V3.Form.currentTarget
        Js.log(formElements)
      }}>
      {tapsEmpty
        ? <p> {React.string("Naražte sudy!")} </p>
        : {
            let options =
              tapsWithKegs
              ->Belt.Map.String.toArray
              ->Array.map(((tapName, keg)) => {
                {
                  text: `${tapName}: ${keg.beer}`,
                  value: tapName,
                }
              })
            <select name="tap" defaultValue={preferredTap}>
              {options
              ->Array.map(({text, value}) => {
                <option key={value} value={value}> {React.string(text)} </option>
              })
              ->React.array}
            </select>
          }}
      <fieldset disabled={tapsEmpty}>
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
