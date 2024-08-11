type submitValues = {email: string, password: string}

module FormFields = {
  type state = {email: string, password: string, passwordConfirmation: string}
  type rec field<_> =
    | Email: field<string>
    | Password: field<string>
    | PasswordConfirmation: field<string>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Email => state.email
      | Password => state.password
      | PasswordConfirmation => state.passwordConfirmation
      }
  let set:
    type value. (state, field<value>, value) => state =
    (state, field, value) =>
      switch field {
      | Email => {...state, email: value}
      | Password => {...state, password: value}
      | PasswordConfirmation => {...state, passwordConfirmation: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@genType @react.component
let make = (~isOnline, ~onSubmit, ~onGoBack) => {
  let form = Form.use(
    ~initialState={email: "", password: "", passwordConfirmation: ""},
    ~onSubmit=({state, raiseSubmitFailed}) => {
      let {email, password} = state.values
      onSubmit({email, password})
      ->Promise.catch(error => {
        let errorMessage = switch FirebaseError.toFirebaseError(error) {
        | FirebaseError.EmailExists => `Tento e${HtmlEntities.nbhp}mail už je zaregistrovaný.`
        | _ =>
          let exn = Js.Exn.asJsExn(error)->Option.getExn
          LogUtils.captureException(exn)
          switch Js.Exn.message(exn) {
          | Some(msg) => `Chyba: ${msg}`
          | None => "Neznámá chyba"
          }
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
  <UnauthenticatedTemplate ?isOnline>
    <h2> {React.string("Registrace")} </h2>
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
                  autoComplete="username email"
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
                  autoComplete="new-password"
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
                inputName="passwordConfirmation"
                inputSlot={<input
                  autoComplete="new-password"
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
      <button className={Styles.link.base} onClick={_ => onGoBack()} type_="button">
        {React.string(`Zpět na přihlášení.`)}
      </button>
    </p>
  </UnauthenticatedTemplate>
}
