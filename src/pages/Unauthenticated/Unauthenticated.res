type classesType = {root: string, small: string}

@module("./Unauthenticated.module.css") external classes: classesType = "default"

module FormFields = %lenses(type state = {email: string, password: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

module Pure = {
  @genType @react.component
  let make = (
    ~initialEmail,
    ~isStandaloneMode,
    ~onCreateAccount,
    ~onGoogleAuth,
    ~onPasswordAuth,
  ) => {
    let form = Form.use(
      ~initialState={email: initialEmail, password: ""},
      ~onSubmit=({state, raiseSubmitFailed}) => {
        onPasswordAuth(state.values)
        ->Promise.catch(error => {
          let errorMessage = switch FirebaseError.toFirebaseError(error) {
          | FirebaseError.InvalidPassword => `Špatný e${HtmlEntities.nbhp}mail nebo heslo`
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
        ])
      },
      ~validationStrategy=OnDemand,
      (),
    )
    let (createAccount, setCreateAccount) = React.useState(() => false)
    <div className={`${Styles.page.centered} ${classes.root}`}>
      <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
      {createAccount
        ? <CreateAccountForm onCreateAccount onGoBack={_ => setCreateAccount(_ => false)} />
        : <>
            <h2> {React.string("Přihlášení")} </h2>
            <Form.Provider value=Some(form)>
              <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
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
                  <p className={Styles.messageBar.danger}>
                    {
                      let errorMessage = switch maybeErrorMessage {
                      | Some(msg) => msg
                      | None => "Neznámá chyba"
                      }
                      React.string(errorMessage)
                    }
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
              <button
                className={Styles.link.base}
                onClick={_ => setCreateAccount(_ => true)}
                type_="button">
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
          </>}
    </div>
  }
}

let signInWithEmailChecked = ref(false)
let useSignInWithEmailRedirect = auth => {
  if !signInWithEmailChecked.contents {
    signInWithEmailChecked := true
    let href = Webapi.Dom.location->Webapi.Dom.Location.href
    if Firebase.Auth.isSignInWithEmailLink(. auth, ~href) {
      let email = switch AppStorage.getPendingEmail() {
      | Some(email) => email
      | None => Webapi.Dom.Window.prompt(window, "Zadejte e-mail se kterým se chcete přihlásit")
      }
      let signInPromise =
        Firebase.Auth.signInWithEmailLink(. auth, ~email, ~href)
        ->Promise.then(_ => {
          AppStorage.removePendingEmail()
          if AppStorage.getThrustDevice()->Option.isSome {
            AppStorage.setRememberEmail(email)
          }
          Promise.resolve()
        })
        ->Promise.finally(() => {
          let url = RescriptReactRouter.dangerouslyGetInitialUrl()
          RescriptReactRouter.replace(RouterUtils.joinPath(url.path))
        })
      // throw promise which triggers a Suspense
      raise(signInPromise->TypeUtils.any)
    }
  }
}

@react.component
let make = () => {
  open Firebase.Auth
  let auth = Reactfire.useAuth()
  useSignInWithEmailRedirect(auth)
  let isStandaloneModeStatus = DomUtils.useIsStandaloneMode()

  <Pure
    initialEmail={AppStorage.getRememberEmail()->Option.getWithDefault("")}
    isStandaloneMode=isStandaloneModeStatus.data
    onCreateAccount={({email, password}) => {
      createUserWithEmailAndPassword(. auth, ~email, ~password)->Promise.then(_ => {
        if AppStorage.getThrustDevice()->Option.isSome {
          AppStorage.setRememberEmail(email)
        }
        Promise.resolve()
      })
    }}
    onGoogleAuth={() => {
      signInWithRedirect(. auth, FederatedAuthProvider.googleAuthProvider())
      ->Promise.catch(error => {
        Js.log(error)
        Promise.reject(error)
      })
      ->ignore
    }}
    onPasswordAuth={({email, password}) => {
      signInWithEmailAndPassword(. auth, ~email, ~password)->Promise.then(_ => {
        if AppStorage.getThrustDevice()->Option.isSome {
          AppStorage.setRememberEmail(email)
        }
        Promise.resolve()
      })
    }}
  />
}
