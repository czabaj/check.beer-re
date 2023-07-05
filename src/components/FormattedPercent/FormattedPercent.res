@react.component
let make = (~value) => {
  React.cloneElement(
    <ReactIntl.FormattedNumber value={value} maximumFractionDigits={1} minimumFractionDigits={1} />,
    {"style": "unit", "unit": "percent"},
  )
}
