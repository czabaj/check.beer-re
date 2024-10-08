module FormFields = {
  type state = {
    personName: string,
    placeName: string,
  }
  type rec field<_> =
    | PersonName: field<string>
    | PlaceName: field<string>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | PersonName => state.personName
      | PlaceName => state.placeName
      }
  let set:
    type value. (state, field<value>, value) => state =
    (state, field, value) =>
      switch field {
      | PersonName => {...state, personName: value}
      | PlaceName => {...state, placeName: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~initialPersonName, ~onDismiss, ~onSubmit) => {
  let form = Form.use(
    ~initialState={
      personName: initialPersonName,
      placeName: "",
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
      Validators.schema([Validators.required(PlaceName), Validators.required(PersonName)])
    },
    ~validationStrategy=OnDemand,
    (),
  )

  <DialogForm formId="add_place" heading="Nové místo" onDismiss visible=true>
    <Form.Provider value={Some(form)}>
      <form autoComplete="off" id="add_place" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`}>
          <Form.Field
            field=PlaceName
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="placeName"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string("Název místa")}
              />
            }}
          />
          <Form.Field
            field=PersonName
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="personName"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string("Moje přezdívka")}
              />
            }}
          />
        </fieldset>
      </form>
    </Form.Provider>
  </DialogForm>
}
