module FormFields = %lenses(
  type state = {
    createdAt: string,
    name: string,
  }
)

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~initialValues, ~onDismiss, ~onSubmit) => {
  let form = Form.use(
    ~initialState=initialValues,
    ~onSubmit=({state}) => {
      onSubmit(state.values)
      None
    },
    ~validationStrategy=OnDemand,
    ~schema={
      open Validators
      schema([required(Name)])
    },
    (),
  )

  <DialogForm formId="basicInfo" heading="Základní údaje místa" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="basicInfo" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`}>
          <Form.Field
            field=Name
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="name"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string("Název")}
              />
            }}
          />
          <Form.Field
            field=CreatedAt
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="created"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="date"
                  value={field.value}
                />}
                labelSlot={React.string("Založeno")}
              />
            }}
          />
        </fieldset>
      </form>
      {switch form.state.formState {
      | SubmitFailed(maybeErrorMessage) => {
          let errorMessage = switch maybeErrorMessage {
          | Some(msg) => msg
          | None => "Neznámá chyba"
          }
          React.string(errorMessage)
        }
      | _ => React.null
      }}
    </Form.Provider>
  </DialogForm>
}
