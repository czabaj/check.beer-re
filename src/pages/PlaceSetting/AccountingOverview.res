type classesType = {descriptionList: string}
@module("./AccountingOverview.module.css") external classes: classesType = "default"

@react.component
let make = (~chargedKegs: array<Db.kegConverted>, ~untappedChargedKegs: array<Db.kegConverted>) => {
  let totalCharged = chargedKegs->Array.reduce(0, (sum, keg) => sum + keg.price)
  let totalUntapped = untappedChargedKegs->Array.reduce(0, (sum, keg) => sum + keg.price)
  <SectionWithHeader
    buttonsSlot={React.null}
    headerId="accounting_overview"
    headerSlot={React.string("Účetnictví")}>
    <dl className={classes.descriptionList}>
      <dt> {React.string("Na skladě")} </dt>
      <dd>
        <FormattedCurrency value={totalUntapped} />
      </dd>
      <dt> {React.string("Na čepu")} </dt>
      <dd>
        <FormattedCurrency value={totalCharged - totalUntapped} />
      </dd>
      <dt> {React.string("Dohromady")} </dt>
      <dd>
        <FormattedCurrency value={totalCharged} />
      </dd>
    </dl>
  </SectionWithHeader>
}
