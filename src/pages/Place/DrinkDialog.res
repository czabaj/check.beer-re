type classesType = {
  consumptions: string,
  root: string,
  taps: string,
  unfinishedConsumptions: string,
}

@module("./DrinkDialog.module.css") external classes: classesType = "default"

module FormFields = %lenses(type state = {tap: string, consumption: int})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

type selectOption = {text: string, value: string}

type unfinishedConsumptionsRecord = {
  consumptionId: string,
  kegId: string,
  beer: string,
  milliliters: int,
  createdAt: Js.Date.t,
}

@react.component
let make = (
  ~personName,
  ~preferredTap,
  ~onDeleteConsumption,
  ~onDismiss,
  ~onSubmit,
  ~tapsWithKegs: Js.Dict.t<Db.kegConverted>,
  ~unfinishedConsumptions: array<unfinishedConsumptionsRecord>,
) => {
  let tapsEntries = tapsWithKegs->Js.Dict.entries
  let tapsOptions = tapsEntries->Array.map(((tapName, keg)) => {
    {
      text: `${tapName}: ${keg.beer} ${keg.serialFormatted}`,
      value: tapName,
    }
  })
  let preferredTapHasKeg = tapsOptions->Array.some(({value}) => value === preferredTap)
  let form = Form.use(
    ~initialState={
      {
        tap: preferredTapHasKeg
          ? preferredTap
          : tapsOptions->Array.get(0)->Option.map(({value}) => value)->Option.getWithDefault(""),
        consumption: -1,
      }
    },
    ~onSubmit=({state, raiseSubmitFailed}) => {
      onSubmit(state.values)
      ->Promise.catch(error => {
        let errorMessage = switch error {
        | Js.Exn.Error(e) =>
          switch Js.Exn.message(e) {
          | Some(msg) => `Chyba: ${msg}`
          | None => "Neznámá chyba"
          }
        | _ => "Neznámá chyba"
        }
        raiseSubmitFailed(Some(errorMessage))
        Promise.resolve()
      })
      ->ignore
      None
    },
    ~schema={
      open! Validators
      schema([required(Tap)])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <Dialog className={classes.root} onClickOutside={onDismiss} visible={true}>
    <header>
      <h3> {React.string(personName)} </h3>
    </header>
    {tapsOptions->Array.length === 0
      ? <p> {React.string("Naražte sudy!")} </p>
      : {
          <Form.Provider value=Some(form)>
            <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
              {<Form.Field
                field=Tap
                render={field => {
                  let handleChange = ReForm.Helpers.handleChange(field.handleChange)
                  <fieldset className={classes.taps}>
                    {tapsOptions
                    ->Array.map(({text, value}) => {
                      <label key=value>
                        <input
                          type_="radio"
                          name="tap"
                          value={value}
                          checked={field.value === value}
                          onChange={handleChange}
                        />
                        <span> {React.string(text)} </span>
                      </label>
                    })
                    ->React.array}
                  </fieldset>
                }}
              />}
              <Form.Field
                field=Consumption
                render={field => {
                  let handleChange = event => {
                    let value =
                      ReactEvent.Form.target(event)["value"]->Int.fromString->Option.getExn
                    field.handleChange(value)
                    form.submit()
                  }
                  <fieldset className={classes.consumptions}>
                    <label>
                      <SvgComponents.BeerGlassLarge />
                      <input
                        checked={field.value === 500}
                        name="consumption"
                        onChange=handleChange
                        type_="radio"
                        value="500"
                      />
                      <span> {React.string("Velké")} </span>
                    </label>
                    <label>
                      <SvgComponents.BeerGlassSmall />
                      <input
                        checked={field.value === 300}
                        name="consumption"
                        onChange=handleChange
                        type_="radio"
                        value="300"
                      />
                      <span> {React.string("Malé")} </span>
                    </label>
                  </fieldset>
                }}
              />
            </form>
          </Form.Provider>
        }}
    <details className=classes.unfinishedConsumptions>
      <summary id="unfinished_consumptions"> {React.string("Nezaúčtovaná piva")} </summary>
      {unfinishedConsumptions->Array.length === 0
        ? <p> {React.string(`${personName} nemá nezaúčtovaná piva.`)} </p>
        : <table
            ariaLabelledby="unfinished_consumptions" className={Styles.tableClasses.consumptions}>
            <thead>
              <tr>
                <th scope="col"> {React.string("Pivo")} </th>
                <th scope="col"> {React.string("Objem")} </th>
                <th scope="col"> {React.string("Kdy")} </th>
                <th scope="col">
                  <span className={Styles.utilityClasses.srOnly}> {React.string("Akce")} </span>
                </th>
              </tr>
            </thead>
            <tbody>
              {unfinishedConsumptions
              ->Array.map(consumption => {
                let createdAt = consumption.createdAt->Js.Date.toISOString
                <tr key={createdAt}>
                  <td> {React.string(consumption.beer)} </td>
                  <td>
                    <FormattedVolume milliliters=consumption.milliliters />
                  </td>
                  <td>
                    <FormattedDateTime value=consumption.createdAt />
                  </td>
                  <td>
                    <button
                      className={`${Styles.buttonClasses.button}`}
                      onClick={_ => onDeleteConsumption(consumption)}
                      type_="button">
                      {React.string("🗑️ Smáznout")}
                    </button>
                  </td>
                </tr>
              })
              ->React.array}
            </tbody>
          </table>}
    </details>
  </Dialog>
}
