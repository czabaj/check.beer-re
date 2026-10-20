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

let maxNameLength = 30

let normalizeName = name => name->String.trim->String.toLowerCase

@react.component
let make = (~existingNames: array<string>, ~initialName, ~onDismiss, ~onSubmit) => {
  let normalizedExistingNames = React.useMemo1(
    () => existingNames->Array.map(normalizeName),
    [existingNames],
  )
  let form = Form.use(
    ~initialState={name: initialName},
    ~onSubmit=({state}) => {
      onSubmit({FormFields.name: state.values.name->String.trim})->ignore
      None
    },
    ~schema={
      open Validators
      schema([
        custom(({name}) => {
          switch name->String.trim {
          | "" => Error("Jméno je povinné")
          | trimmed if trimmed->String.length > maxNameLength =>
            Error(`Jméno může mít nejvýše ${maxNameLength->Int.toString} znaků`)
          | trimmed if normalizedExistingNames->Array.includes(trimmed->normalizeName) =>
            Error("Takové jméno již evidujeme")
          | _ => Valid
          }
        }, Name),
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )

  <DialogForm formId="renamePerson" heading="Přejmenovat osobu" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="renamePerson" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className="reset">
          <Form.Field
            field=Name
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="name"
                inputSlot={<input
                  maxLength=maxNameLength
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string("Jméno")}
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
