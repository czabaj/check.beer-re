module FormFields = %lenses(type state = {email: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@genType @react.component
let make = (~initialEmail, ~isOnline, ~onGoBack, ~onSubmit) => {
  let form = Form.use(
    ~initialState={email: initialEmail},
    ~onSubmit=({state, raiseSubmitFailed}) => {
      onSubmit(state.values)
      ->Promise.catch(error => {
        switch FirebaseError.toFirebaseError(error) {
        | _ =>
          let exn = Js.Exn.asJsExn(error)->Option.getExn
          LogUtils.captureException(error)
          let errorMessage = switch Js.Exn.message(exn) {
          | Some(msg) => `Chyba: ${msg}`
          | None => "Neznámá chyba"
          }
          raiseSubmitFailed(Some(errorMessage))
        }
        Promise.resolve()
      })
      ->ignore
      None
    },
    ~schema={
      Validators.schema([Validators.required(Email), Validators.email(Email)])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <UnauthenticatedTemplate ?isOnline>
    <h2> {React.string("Zapomenuté heslo")} </h2>
    <Form.Provider value=Some(form)>
      <form className={Styles.stack.base} onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`}>
          <Form.Field
            field=Email
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="email"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="email"
                  value={field.value}
                />}
                labelSlot={React.string(`E${HtmlEntities.nbhp}mail`)}
              />
            }}
          />
        </fieldset>
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
        <button className={Styles.button.base} type_="submit">
          {React.string(`Resetovat heslo`)}
        </button>
      </form>
      <p>
        {React.string(`Jste tu omylem? `)}
        <button className={Styles.link.base} onClick={_ => onGoBack()} type_="button">
          {React.string(`Zpět na přihlášení.`)}
        </button>
      </p>
    </Form.Provider>
  </UnauthenticatedTemplate>
}
