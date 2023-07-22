type classesType = {root: string}
@module("./InputDonors.module.css") external classes: classesType = "default"

@gentype @react.component
let make = (~errorMessage=?, ~legendSlot=?, ~persons: Map.t<string, string>, ~value, ~onChange) => {
  let {minorUnit} = FormattedCurrency.useCurrency()
  let (valueEntries, unusedPersons, amountsSum) = React.useMemo1(() => {
    let entries = value->Dict.toArray
    let unused =
      persons
      ->Map.entries
      ->Iterator.toArray
      ->Array.filter(((personId, _)) => value->Dict.get(personId) === None)
    let sum = entries->Array.reduce(0, (acc, (_, amount)) => acc + amount)
    (entries, unused, sum)
  }, [value])
  <fieldset className={`reset ${classes.root}`}>
    {switch legendSlot {
    | None => React.null
    | Some(legend) => <legend> {legend} </legend>
    }}
    <table>
      <thead>
        <tr>
          <th scope="col"> {React.string("Jméno")} </th>
          <th scope="col"> {React.string("Částka")} </th>
          <th scope="col">
            <span className=Styles.utility.srOnly> {React.string("Akce")} </span>
          </th>
        </tr>
      </thead>
      <tbody>
        {valueEntries
        ->Array.map(((personId, amount)) => {
          <tr key={personId}>
            <th scope="row"> {React.string(persons->Map.get(personId)->Option.getExn)} </th>
            <td>
              <input
                min="0"
                onChange={e => {
                  let target = e->ReactEvent.Form.target
                  let newAmount = target["valueAsNumber"]
                  let newAmountInt = (newAmount *. minorUnit)->Int.fromFloat
                  let newValue = value->Dict.copy
                  newValue->Dict.set(personId, newAmountInt)
                  onChange(newValue)
                }}
                step=1.
                type_="number"
                value={(amount->Float.fromInt /. minorUnit)->Float.toString}
              />
            </td>
            <td>
              <button
                className={`${Styles.button.base} ${Styles.button.iconOnly} ${Styles.button.sizeExtraSmall}`}
                onClick={_ => {
                  let newValue = value->Dict.copy
                  newValue->Dict.delete(personId)
                  onChange(newValue)
                }}
                title="Odebrat vkladatele"
                type_="button">
                {React.string("❌")}
              </button>
            </td>
          </tr>
        })
        ->React.array}
      </tbody>
      <tbody>
        <tr>
          <td colSpan=2>
            <select
              disabled={unusedPersons->Array.length === 0}
              onChange={event => {
                let person = ReactEvent.Form.target(event)["value"]
                if person !== "" {
                  let newValue = value->Dict.copy
                  newValue->Dict.set(person, 0)
                  onChange(newValue)
                }
              }}
              value="">
              <option disabled={true} value=""> {React.string("Přidat vkladatele")} </option>
              {unusedPersons
              ->Array.map(((personId, name)) =>
                <option key={personId} value={personId}> {React.string(name)} </option>
              )
              ->React.array}
            </select>
          </td>
        </tr>
      </tbody>
      <tfoot>
        <tr>
          <th scope="row"> {React.string("Celkem")} </th>
          <td colSpan=2>
            <FormattedCurrency value={amountsSum} />
          </td>
        </tr>
      </tfoot>
    </table>
    {switch errorMessage {
    | None => React.null
    | Some(errorMessage) => <InputWrapper.ErrorMessage message={errorMessage} />
    }}
  </fieldset>
}
