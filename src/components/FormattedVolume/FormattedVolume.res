@react.component
let make = (~milliliters) => {
  let liters = milliliters->Int.toFloat /. 1000.0
  React.cloneElement(
    <ReactIntl.FormattedNumber
      value={liters} maximumFractionDigits={1} minimumFractionDigits={1}
    />,
    {"style": "unit", "unit": "liter"},
  )
}
