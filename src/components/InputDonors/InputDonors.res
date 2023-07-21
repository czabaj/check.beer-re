type classesType = {root: string}
@module("./InputDonors.module.css") external classes: classesType = "default"

@gentype @react.component
let make = (~errorMessage=?, ~legendSlot=?, ~persons, ~value, ~onChange) => {
  let {minorUnit} = FormattedCurrency.useCurrency()
  let (valueEntries, availableNames, amountsSum) = React.useMemo1(() => {
    let entries = value->Dict.toArray
    let names = entries->Array.map(((name, _)) => name)
    let usedNames = Set.fromArray(names)
    let unusedNames = persons->Array.filter(name => !(usedNames->Set.has(name)))
    let sum = entries->Array.reduce(0, (acc, (_, amount)) => acc + amount)
    (entries, unusedNames, sum)
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
        ->Array.map(((name, amount)) => {
          <tr key={name}>
            <th scope="row"> {React.string(name)} </th>
            <td>
              <input
                min="0"
                onChange={e => {
                  let target = e->ReactEvent.Form.target
                  let newAmount = target["valueAsNumber"]
                  let newAmountInt = (newAmount *. minorUnit)->Int.fromFloat
                  let newValue = value->Dict.copy
                  newValue->Dict.set(name, newAmountInt)
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
                  newValue->Dict.delete(name)
                  onChange(newValue)
                }}
                title="Odebrat donátora"
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
          <td>
            <select
              disabled={availableNames->Array.length === 0}
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
              {availableNames
              ->Array.map(name => <option key={name} value={name}> {React.string(name)} </option>)
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
