let context = React.createContext("CZK")

@module("./minorUnits.js")
external minorUnits: Dict.t<float> = "minorUnits"

@react.component
let make = (~value) => {
  let currency = React.useContext(context)
  let minorUnit = minorUnits->Dict.get(currency)->Option.getWithDefault(100.0)

  <ReactIntl.FormattedNumber currency style=#currency value={value->Float.fromInt /. minorUnit} />
}

module Provider = {
  let make = context->React.Context.provider
}
