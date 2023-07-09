type classesType = {descriptionList: string}
@module("./PlaceStats.module.css") external classes: classesType = "default"

@react.component
let make = (~chargedKegsValue, ~personsCount, ~totalBalance) => {
  <SectionWithHeader
    buttonsSlot={<a
      {...RouterUtils.createAnchorProps("./osob")}
      className={Styles.buttonClasses.button}
      type_="button">
      {React.string("Správa osob")}
    </a>}
    headerId="accounting_overview"
    headerSlot={React.string("Statistika")}>
    <dl className={classes.descriptionList}>
      <dt> {React.string("Počet konzumentů")} </dt>
      <dd>
        <ReactIntl.FormattedNumber value={personsCount->Float.fromInt} />
      </dd>
      <dt> {React.string("Na skladě")} </dt>
      <dd>
        <FormattedCurrency value={chargedKegsValue} />
      </dd>
      <dt> {React.string("Platby")} </dt>
      <dd>
        <FormattedCurrency value={totalBalance} />
      </dd>
    </dl>
  </SectionWithHeader>
}
