type classesType = {descriptionList: string}
@module("./PlaceStats.module.css") external classes: classesType = "default"

@react.component
let make = (~chargedKegsValue, ~isUserAuthorized, ~personsCount) => {
  <SectionWithHeader
    buttonsSlot={isUserAuthorized(UserRoles.Admin)
      ? <a
          {...RouterUtils.createAnchorProps("./osob")}
          className={Styles.button.base}
          type_="button">
          {React.string("Osobní účty")}
        </a>
      : React.null}
    headerId="accounting_overview"
    headerSlot={React.string("Účetnictví")}>
    <dl className={classes.descriptionList}>
      <dt> {React.string("Počet hostů")} </dt>
      <dd>
        <ReactIntl.FormattedNumber value={personsCount->Float.fromInt} />
      </dd>
      <dt> {React.string("Hodnota sudů na skladě")} </dt>
      <dd>
        <FormattedCurrency value={chargedKegsValue} />
      </dd>
    </dl>
  </SectionWithHeader>
}
