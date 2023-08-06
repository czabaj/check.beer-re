type classesType = {root: string}

@module("./SignInForm.module.css") external classes: classesType = "default"

module FormFields = %lenses(type state = {email: string, password: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

let wrongPasswordMessage = "@@wrong-password"

@genType @react.component
let make = (
  ~initialEmail,
  ~isStandaloneMode,
  ~onForgottenPassword,
  ~onGoogleAuth,
  ~onPasswordAuth,
  ~onSignUp,
) => {
  let form = Form.use(
    ~initialState={email: initialEmail, password: ""},
    ~onSubmit=({state, raiseSubmitFailed}) => {
      onPasswordAuth(state.values)
      ->Promise.catch(error => {
        let errorMessage = switch FirebaseError.toFirebaseError(error) {
        | FirebaseError.InvalidPassword => wrongPasswordMessage
        | Js.Exn.Error(e) =>
          LogUtils.captureException(e)
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
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <UnauthenticatedTemplate className={classes.root}>
    <h2> {React.string("Přihlášení")} </h2>
    <Form.Provider value=Some(form)>
      <form className={Styles.stack.base} onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`}>
          {switch isStandaloneMode {
          | Some(true) => React.null
          | _ => <InputThrustDevice />
          }}
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
        </fieldset>
        {switch form.state.formState {
        | SubmitFailed(maybeErrorMessage) =>
          <p className={Styles.messageBar.danger} role="alert">
            {switch maybeErrorMessage {
            | None => React.string("Neznámá chyba")
            | Some(message) =>
              message !== wrongPasswordMessage
                ? React.string(message)
                : <>
                    {React.string(
                      `Špatný e${HtmlEntities.nbhp}mail nebo heslo. Zapomněli jste heslo? `,
                    )}
                    <button
                      className={Styles.link.base}
                      onClick={_ => onForgottenPassword(form.values.email)}
                      type_="button">
                      {React.string(`Obnovte heslo přes e${HtmlEntities.nbhp}mail.`)}
                    </button>
                  </>
            }}
          </p>

        | _ => React.null
        }}
        <button className={Styles.button.base} type_="submit">
          {React.string(`Přihlásit se heslem`)}
        </button>
      </form>
    </Form.Provider>
    <p>
      {React.string(`Nemáte účet? `)}
      <button className={Styles.link.base} onClick={_ => onSignUp()} type_="button">
        {React.string(`Zaregistrujte se.`)}
      </button>
    </p>
    <section ariaLabelledby="other_methods">
      <h3 id="other_methods">
        <span> {React.string("nebo")} </span>
      </h3>
      <button className={Styles.button.base} onClick={_ => onGoogleAuth()} type_="button">
        {React.string("Přihlásit přes Google")}
      </button>
    </section>
  </UnauthenticatedTemplate>
}
