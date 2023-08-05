type submitValues = {email: string, password: string}

module FormFields = %lenses(
  type state = {email: string, password: string, passwordConfirmation: string}
)

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~onCreateAccount, ~onGoBack) => {
  let form = Form.use(
    ~initialState={email: "", password: "", passwordConfirmation: ""},
    ~onSubmit=({state, raiseSubmitFailed}) => {
      let {email, password} = state.values
      onCreateAccount({email, password})
      ->Promise.catch(error => {
        let errorMessage = switch FirebaseError.toFirebaseError(error) {
        | FirebaseError.EmailExists => `Tento e${HtmlEntities.nbhp}mail už je zaregistrovaný.`
        | Js.Exn.Error(e) =>
          Sentry.captureException(e)
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
      Validators.schema([
        Validators.required(Email),
        Validators.email(Email),
        Validators.required(Password),
        Validators.password(Password),
        Validators.matchField(
          ~error="Hesla se neshodují",
          ~secondField=Password,
          PasswordConfirmation,
        ),
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <>
    <h2> {React.string("Registrace")} </h2>
    <Form.Provider value=Some(form)>
      <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
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
          <Form.Field
            field=Password
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="password"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="password"
                  value={field.value}
                />}
                labelSlot={React.string(`Heslo`)}
              />
            }}
          />
          <Form.Field
            field=PasswordConfirmation
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="password"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="password"
                  value={field.value}
                />}
                labelSlot={React.string(`Heslo znovu`)}
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
          {React.string(`Zaregistrovat se`)}
        </button>
      </form>
    </Form.Provider>
    <p>
      {React.string(`Jste tu omylem? `)}
      <button className={Styles.link.base} onClick={onGoBack} type_="button">
        {React.string(`Zpět na přihlášení.`)}
      </button>
    </p>
  </>
}
