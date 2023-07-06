@react.component
let make = (~children: (~formattedNumber: string) => React.element=?, ~milliliters) => {
  let liters = milliliters->Int.toFloat /. 1000.0
  React.cloneElement(
    <ReactIntl.FormattedNumber
      ?children value={liters} maximumFractionDigits={1} minimumFractionDigits={1}
    />,
    {"style": "unit", "unit": "liter"},
  )
}
