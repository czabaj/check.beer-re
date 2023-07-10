type classesType = {descriptionList: string}
@module("./PlaceStats.module.css") external classes: classesType = "default"

@react.component
let make = (~chargedKegsValue, ~personsCount, ~totalBalance) => {
  <SectionWithHeader
    buttonsSlot={<a
      {...RouterUtils.createAnchorProps("./osob")}
      className={Styles.buttonClasses.button}
      type_="button">
      {React.string("Osobní účty")}
    </a>}
    headerId="accounting_overview"
    headerSlot={React.string("Účetnictví")}>
    <dl className={classes.descriptionList}>
      <dt> {React.string("Počet návštěvníků")} </dt>
      <dd>
        <ReactIntl.FormattedNumber value={personsCount->Float.fromInt} />
      </dd>
      <dt> {React.string("Hodnota sudů na skladě")} </dt>
      <dd>
        <FormattedCurrency value={chargedKegsValue} />
      </dd>
      <dt> {React.string("Celková bilance")} </dt>
      <dd>
        <FormattedCurrency format={FormattedCurrency.formatAccounting} value={totalBalance} />
      </dd>
    </dl>
  </SectionWithHeader>
}
