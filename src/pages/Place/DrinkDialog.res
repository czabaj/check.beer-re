type classesType = {
  consumptions: string,
  root: string,
  taps: string,
  unfinishedConsumptions: string,
}

@module("./DrinkDialog.module.css") external classes: classesType = "default"

module FormFields = {
  type state = {tap: string, consumption: int}
  type rec field<_> =
    | Tap: field<string>
    | Consumption: field<int>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Tap => state.tap
      | Consumption => state.consumption
      }
  let set:
    type value. (state, field<value>, value) => state =
    (state, field, value) =>
      switch field {
      | Tap => {...state, tap: value}
      | Consumption => {...state, consumption: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

type selectOption = {text: React.element, value: string}

@react.component
let make = (
  ~personName,
  ~preferredTap,
  ~onDeleteConsumption,
  ~onDismiss,
  ~onSubmit,
  ~tapsWithKegs: Js.Dict.t<Db.kegConverted>,
  ~unfinishedConsumptions: array<Db.userConsumption>,
) => {
  let tapsOptions = React.useMemo1(() => {
    let tapsEntries = tapsWithKegs->Js.Dict.entries
    tapsEntries->Array.map(((tapName, keg)) => {
      {
        text: <>
          {React.string(`${tapName}: ${keg.beer} ${keg.serialFormatted}`)}
          <MeterKeg keg />
        </>,
        value: tapName,
      }
    })
  }, [tapsWithKegs])
  let unfinishedConsumptionsDesc = React.useMemo1(() => {
    unfinishedConsumptions->Array.toReversed
  }, [unfinishedConsumptions])

  let preferredTapHasKeg = tapsOptions->Array.some(({value}) => value === preferredTap)
  let form = Form.use(
    ~initialState={
      {
        tap: preferredTapHasKeg
          ? preferredTap
          : tapsOptions->Array.get(0)->Option.map(({value}) => value)->Option.getOr(""),
        consumption: -1,
      }
    },
    ~onSubmit=({state}) => {
      onSubmit(state.values)->ignore
      None
    },
    ~schema={
      Validators.schema([Validators.required(Tap)])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <Dialog className={classes.root} onClickOutside={onDismiss} visible={true}>
    <header>
      <h3> {React.string(personName)} </h3>
      <button className={Styles.button.base} onClick={_ => onDismiss()} type_="button">
        {React.string("Zavřít")}
      </button>
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
                          checked={field.value === value}
                          className={Styles.radio.base}
                          name="tap"
                          onChange={handleChange}
                          type_="radio"
                          value={value}
                        />
                        <span> {text} </span>
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
                      <img alt="" src=Assets.beerGlassLarge />
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
                      <img alt="" src=Assets.beerGlassSmall />
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
        : <TableConsumptions
            ariaLabelledby="unfinished_consumptions"
            onDeleteConsumption
            unfinishedConsumptions=unfinishedConsumptionsDesc
          />}
    </details>
  </Dialog>
}
