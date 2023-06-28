type classesType = {descriptionList: string}
@module("./AccountingOverview.module.css") external classes: classesType = "default"

type sectionClassesType = {root: string}
@module("./SettingSection.module.css") external sectionClasses: sectionClassesType = "default"

@react.component
let make = (~chargedKegs: array<Db.kegConverted>, ~untappedChargedKegs: array<Db.kegConverted>) => {
  let totalCharged = chargedKegs->Array.reduce(0, (sum, keg) => sum + keg.priceNew)
  let totalUntapped = untappedChargedKegs->Array.reduce(0, (sum, keg) => sum + keg.priceNew)
  <SectionWithHeader
    buttonsSlot={React.null}
    headerId="accounting-overview"
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
