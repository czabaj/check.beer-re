@react.component
let make = React.memo((~dateTime) => {
  let timeDiff = (dateTime->Js.Date.getTime -. Js.Date.now()) /. 1000.0
  <ReactIntl.FormattedRelativeTime numeric=#auto updateIntervalInSeconds={1.0} value={timeDiff} />
})
