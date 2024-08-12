module FormFields = {
  type state = {name: string}
  type rec field<_> = Name: field<string>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Name => state.name
      }
  let set:
    type value. (state, field<value>, value) => state =
    (_state, field, value) =>
      switch field {
      | Name => {name: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~existingNames, ~onDismiss, ~onSubmit) => {
  let form = Form.use(
    ~initialState={name: ""},
    ~onSubmit=({state}) => {
      onSubmit(state.values)->ignore
      None
    },
    ~schema={
      open Validators
      schema([
        required(Name),
        notIn(~haystack=existingNames, ~error="Tato pípa již existuje", Name),
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )

  <DialogForm formId="addTap" heading="Přidat pípu" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="addTap" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className="reset">
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
                labelSlot={React.string("Označení")}
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
