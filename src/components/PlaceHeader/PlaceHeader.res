@react.component
let make = (~buttonRightSlot, ~className=?, ~createdTimestamp, ~placeName) => {
  let createdDate = createdTimestamp->Firebase.Timestamp.toDate
  <Header
    buttonLeftSlot={<a
      {...RouterUtils.createAnchorProps("../")} className={Header.classes.buttonLeft}>
      <span> {React.string("↩️")} </span>
      <span> {React.string("Zpět")} </span>
    </a>}
    buttonRightSlot
    ?className
    headingSlot={React.string(placeName)}
    subheadingSlot={<ReactIntl.FormattedMessage
      id="Place.established"
      defaultMessage={"Založeno {time}"}
      values={{
        "time": <time dateTime={createdDate->Js.Date.toISOString}>
          <ReactIntl.FormattedDate value={createdDate} />
        </time>,
      }}
    />}
  />
}
