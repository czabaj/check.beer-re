@react.component
let make = (~value) => {
  <ReactIntl.FormattedDate
    year=#numeric month=#numeric day=#numeric hour=#numeric minute=#numeric value
  />
}
