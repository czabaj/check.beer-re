type classesType = {root: string}
@module("./PersonDetail.module.css") external classes: classesType = "default"

type unfinishedConsumptionsRecord = {
  consumptionId: string,
  kegId: string,
  beer: string,
  milliliters: int,
  createdAt: Js.Date.t,
}

@react.component
let make = (
  ~hasNext,
  ~hasPrevious,
  ~onDeletePerson,
  ~onDismiss,
  ~onNextPerson,
  ~onPreviousPerson,
  ~person: Db.personsAllRecord,
  ~personId,
  ~placeId,
) => {
  let personStatus = Db.usePlacePersonDocumentStatus(
    ~options={suspense: false},
    placeId,
    personId,
  )
  let (showDeletePersonConfirmation, setShowDeletePersonConfirmation) = React.useState(_ => false)
  <DialogCycling
    className={classes.root}
    hasNext
    hasPrevious
    header={person.name}
    onDismiss
    onNext=onNextPerson
    onPrevious=onPreviousPerson
    visible={true}>
    <section ariaLabel="Základní údaje">
      <dl className={`reset ${Styles.descriptionListClasses.inline}`}>
        <div>
          <dt> {React.string("již od")} </dt>
          <dd>
            {switch personStatus.data {
            | None => <LoadingInline />
            | Some(personDoc) =>
              <FormattedDateTime value={personDoc.createdAt->Firebase.Timestamp.toDate} />
            }}
          </dd>
        </div>
        <div>
          <dt> {React.string("naposledy")} </dt>
          <dd>
            <FormattedDateTime value={person.recentActivityAt->Firebase.Timestamp.toDate} />
          </dd>
        </div>
        <div>
          <dt> {React.string("stav konta")} </dt>
          <dd>
            <FormattedCurrency format={FormattedCurrency.formatAccounting} value=person.balance />
          </dd>
        </div>
      </dl>
    </section>
    {!showDeletePersonConfirmation
      ? React.null
      : <DialogConfirmation
          className={DialogConfirmation.classes.deleteConfirmation}
          heading="Odstranit osobu ?"
          onConfirm={() => {
            onDismiss()
            onDeletePerson()
          }}
          onDismiss={() => setShowDeletePersonConfirmation(_ => false)}
          visible=true>
          <p>
            {React.string(`Chystáte se odstranit osobu `)}
            <b> {React.string(person.name)} </b>
            {React.string(` z aplikace. Nemá žádnou historii konzumací ani účetních transakcí. Chcete pokračovat?`)}
          </p>
        </DialogConfirmation>}
  </DialogCycling>
}
