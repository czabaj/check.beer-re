@react.component
let make = (~ariaLabel=?, ~ariaLabelledby=?, ~keg: Db.kegConverted) => {
  let volume = keg.milliliters
  <FormattedVolume milliliters={Math.Int.max(volume - keg.consumptionsSum, 0)}>
    {(~formattedNumber) =>
      <meter
        ?ariaLabel
        ?ariaLabelledby
        low={volume / 3}
        max={volume->Int.toString}
        min="0"
        title={formattedNumber}
        value={(volume - keg.consumptionsSum)->Int.toString}>
        {React.string(formattedNumber)}
      </meter>}
  </FormattedVolume>
}
