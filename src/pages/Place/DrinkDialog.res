type classesType = {root: string}

@module("./DrinkDialog.module.css") external classes: classesType = "default"

module FormFields = %lenses(type state = {tap: string, consumption: int})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

type selectOption = {text: string, value: string}

@react.component
let make = (
  ~personName,
  ~preferredTap,
  ~onDismiss,
  ~onSubmit,
  ~tapsWithKegs: Belt.Map.String.t<Db.kegConverted>,
) => {
  let tapsEmpty = tapsWithKegs->Belt.Map.String.isEmpty
  let options =
    tapsWithKegs
    ->Belt.Map.String.toArray
    ->Array.map(((tapName, keg)) => {
      {
        text: `${tapName}: ${keg.beer}`,
        value: tapName,
      }
    })
  let preferredTapHasKeg = options->Array.some(({value}) => value === preferredTap)
  let form = Form.use(
    ~initialState={
      {
        tap: preferredTapHasKeg
          ? preferredTap
          : options->Array.get(0)->Option.map(({value}) => value)->Option.getWithDefault(""),
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
    {tapsEmpty
      ? <p> {React.string("Naražte sudy!")} </p>
      : {
          <Form.Provider value=Some(form)>
            <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
              {<Form.Field
                field=Tap
                render={field => {
                  <InputWrapper
                    inputError=?{field.error}
                    inputName="tap"
                    inputSlot={<select
                      onChange={ReForm.Helpers.handleChange(field.handleChange)}
                      value={field.value}>
                      {options
                      ->Array.map(({text, value}) => {
                        <option key={value} value={value}> {React.string(text)} </option>
                      })
                      ->React.array}
                    </select>}
                    labelSlot={React.string(`Z${HtmlEntities.nbsp}pípy:`)}
                  />
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
                  <fieldset>
                    <legend> {React.string(personName)} </legend>
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
  </Dialog>
}
