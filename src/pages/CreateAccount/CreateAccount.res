module FormFields = %lenses(type state = {name: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

module Pure = {
  @react.component
  let make = (~onSubmit) => {
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
        Validators.schema([Validators.required(Name)])
      },
      ~validationStrategy=OnDemand,
      (),
    )
    <div className={Styles.page.centered}>
      <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
      <h2> {React.string("Dokončení registrace")} </h2>
      <Form.Provider value=Some(form)>
        <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
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
                  labelSlot={React.string(`Vaše přezdívka`)}
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
    </div>
  }
}

@react.component
let make = (~user: Firebase.User.t) => {
  <Pure
    onSubmit={async values => {
      let _ = await Firebase.Auth.updateProfile(user, {displayName: values.name})
    }}
  />
}
