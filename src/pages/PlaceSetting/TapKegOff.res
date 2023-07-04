module FormFields = %lenses(type state = {untapOption: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~keg: Db.kegConverted, ~onSubmit, ~onDismiss, ~tapName) => {
  let form = Form.use(
    ~initialState={
      untapOption: "",
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
      schema([required(UntapOption)])
    },
    ~validationStrategy=OnDemand,
    (),
  )

  <DialogForm formId="tap_keg_off" heading="Odrazit sud ❓" onDismiss visible=true>
    <Form.Provider value={Some(form)}>
      <div>
        <p>
          {React.string("Potvzením odrazíte sud ")}
          <b> {React.string(`${keg.serialFormatted} ${keg.beer}`)} </b>
          {React.string(` z pípy `)}
          <b> {React.string(tapName)} </b>
        </p>
        <p>
          {React.string(`Sud můžete vrátit zpět na sklad, nebo ho dopít a rozúčtovat.
        První varianta umožní sud přerazit na jinou pípu nebo ho prostě nechat na
        skladě, druhá varianta rozpočítá cenu sudu mezi jeho konzumenty a odepíše
        sud ze skladu.`)}
        </p>
        <p>
          <strong>
            {React.string("Pozor, dopitý a rozúčtovaný sud nejde odúčtovat!")}
          </strong>
        </p>
        // TODO: ban finalizing of keg without consumptions
        <form id="tap_keg_off" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
          <Form.Field
            field=UntapOption
            render={field => {
              let handleChange = ReForm.Helpers.handleChange(field.handleChange)
              <fieldset>
                <legend> {React.string("Způsob odražení")} </legend>
                <label>
                  <input
                    checked={field.value === "toStocks"}
                    name="consumption"
                    onChange={handleChange}
                    type_="radio"
                    value="toStocks"
                  />
                  <span> {React.string("Vrátit na sklad")} </span>
                </label>
                <label>
                  <input
                    checked={field.value === "finish"}
                    name="consumption"
                    onChange={handleChange}
                    type_="radio"
                    value="finish"
                  />
                  <span> {React.string("Dopít a rozúčtovat")} </span>
                </label>
                {switch field.error {
                | Some(error) => React.string(error)
                | None => React.null
                }}
              </fieldset>
            }}
          />
        </form>
      </div>
    </Form.Provider>
  </DialogForm>
}
