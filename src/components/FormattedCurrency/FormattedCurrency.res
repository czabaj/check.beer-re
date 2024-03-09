type classesType = {accounting: string}
@module("./FormattedCurrency.module.css") external classes: classesType = "default"

let context = React.createContext("CZK")

@module("./minorUnits.js")
external minorUnits: Dict.t<float> = "minorUnits"

type currencyInfo = {
  currency: string,
  minorUnit: float,
}

let getMinorUnit = currency => {
  minorUnits->Dict.get(currency)->Option.getOr(100.0)
}

let useCurrency = () => {
  let currency = React.useContext(context)
  let minorUnit = getMinorUnit(currency)
  {currency, minorUnit}
}

@react.component
let make = (~value, ~format=?) => {
  let {currency, minorUnit} = useCurrency()

  <ReactIntl.FormattedNumber currency style=#currency value={value->Float.fromInt /. minorUnit}>
    {format->Option.map(fn => fn(value))->Option.getUnsafe}
  </ReactIntl.FormattedNumber>
}

module Provider = {
  let make = context->React.Context.provider
}

let formatAccounting = (value, ~formattedNumber: string) => {
  let negative = value < 0
  React.cloneElement(
    <span />,
    {
      "className": classes.accounting,
      "children": formattedNumber,
      "data-negative": negative->string_of_bool,
    },
  )
}
