type classesType = {iconButton: string, root: string}

@module("./PlaceHeader.module.css") external classes: classesType = "default"

@react.component
let make = (~className=?, ~createdTimestamp, ~placeName, ~slotRightButton) => {
  let createdDate = createdTimestamp->Firebase.Timestamp.toDate
  <header
    className={`${classes.root} ${switch className {
      | None => ""
      | Some(c) => c
      }}`}>
    <h2> {React.string(placeName)} </h2>
    <p>
      <ReactIntl.FormattedMessage
        id="Place.established"
        defaultMessage={"Již od {time}"}
        values={{
          "time": <time dateTime={createdDate->Js.Date.toISOString}>
            <ReactIntl.FormattedDate value={createdDate} />
          </time>,
        }}
      />
    </p>
    <a {...RouterUtils.createAnchorProps("../")} className={classes.iconButton}>
      <span> {React.string("↩️")} </span>
      <span> {React.string("Zpět")} </span>
    </a>
    {slotRightButton}
  </header>
}
