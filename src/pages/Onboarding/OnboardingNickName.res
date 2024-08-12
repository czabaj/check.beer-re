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
      | Name => { name: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@genType @react.component
let make = (~initialName, ~onSubmit) => {
  let form = Form.use(
    ~initialState={name: initialName},
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
      Validators.schema([Validators.required(Name)])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <OnboardingTemplate>
    <h2> {React.string("Jak ti říkají?")} </h2>
    <Form.Provider value=Some(form)>
      <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`}>
          <p className={Styles.fieldset.gridSpan}>
            {React.string(`Tvoje přezdívka se použije pro místa, která založíš.`)}
          </p>
          <p className={Styles.fieldset.gridSpan}>
            {React.string(`Tam, kde jsi hostem můžeš mít jiné jméno, to určuje správce každého místa.`)}
          </p>
          <Form.Field
            field=Name
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="name"
                inputSlot={<input
                  autoComplete="name"
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string(`Přezdívka`)}
              />
            }}
          />
          <button className={`${Styles.button.base} ${Styles.fieldset.gridSpan}`} type_="submit">
            {React.string(`Dokončit registraci`)}
          </button>
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
  </OnboardingTemplate>
}
