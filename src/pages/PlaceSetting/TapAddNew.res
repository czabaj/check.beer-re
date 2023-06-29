module FormFields = %lenses(type state = {name: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~existingNames, ~onDismiss, ~onSubmit) => {
  let form = Form.use(
    ~initialState={name: ""},
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
