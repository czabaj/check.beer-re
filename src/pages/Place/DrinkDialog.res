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
    {tapsEmpty
      ? <p> {React.string("Naražte sudy!")} </p>
      : {
          <form
            onChange={event => {
              let formElement = event->ReactEvent.Form.currentTarget
            }}>
            {
              let options =
                tapsWithKegs
                ->Belt.Map.String.toArray
                ->Array.map(((tapName, keg)) => {
                  {
                    text: `${tapName}: ${keg.beer}`,
                    value: tapName,
                  }
                })
              <InputWrapper
                inputName="tap"
                inputSlot={<select name="tap" defaultValue={preferredTap}>
                  {options
                  ->Array.map(({text, value}) => {
                    <option key={value} value={value}> {React.string(text)} </option>
                  })
                  ->React.array}
                </select>}
                labelSlot={React.string(`Z${HtmlEntities.nbsp}pípy:`)}
              />
            }
            <fieldset>
              <legend> {React.string(personName)} </legend>
              <label>
                <SvgComponents.BeerGlassLarge />
                <input name="consumption" type_="radio" value="500" />
                <span> {React.string("Velké")} </span>
              </label>
              <label>
                <SvgComponents.BeerGlassSmall />
                <input name="consumption" type_="radio" value="300" />
                <span> {React.string("Malé")} </span>
              </label>
            </fieldset>
          </form>
        }}
  </Dialog>
}
