module FormFields = %lenses(type state = {amount: int, note: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~onDismiss, ~onSubmit, ~personName) => {
  let {minorUnit} = FormattedCurrency.useCurrency()
  let form = Form.use(
    ~initialState={amount: 0, note: ""},
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
      Validators.schema([Validators.intNonZero(~error="Částka nemůže být nulová", Amount)])
    },
    ~validationStrategy=OnDemand,
    (),
  )

  <DialogForm
    formId="addFinancialTransaction" heading="Nový účetní záznam" onDismiss visible=true>
    <p>
      <b> {React.string(personName)} </b>
      {React.string(` obdrží nový účetní záznam.`)}
    </p>
    <Form.Provider value=Some(form)>
      <form id="addFinancialTransaction" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldsetClasses.grid}`}>
          <Form.Field
            field=Amount
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="amount"
                inputSlot={<input
                  onChange={event =>
                    field.handleChange(
                      (ReactEvent.Form.target(event)["valueAsNumber"] *. minorUnit)->Int.fromFloat,
                    )}
                  step=1.0
                  type_="number"
                  value={(field.value->Float.fromInt /. minorUnit)->Float.toString}
                />}
                labelSlot={React.string("Částka")}
              />
            }}
          />
          <Form.Field
            field=Note
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="note"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string("Poznámka")}
              />
            }}
          />
        </fieldset>
      </form>
    </Form.Provider>
  </DialogForm>
}
