type classesType = {root: string, small: string}

@module("./Unauthenticated.module.css") external classes: classesType = "default"

module FormFields = %lenses(type state = {email: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

module Pure = {
  @genType @react.component
  let make = (~initialEmail, ~onBackToForm, ~onGoogleAuth, ~onPasswordAuth, ~signInEmailSent=?) => {
    let isStandaloneModeStatus = DomUtils.useIsStandaloneMode()
    let form = Form.use(
      ~initialState={email: initialEmail},
      ~onSubmit=({state, raiseSubmitFailed}) => {
        onPasswordAuth(state.values)
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
        Validators.schema([Validators.email(Email)])
      },
      ~validationStrategy=OnDemand,
      (),
    )
    <div className={`${Styles.page.centered} ${classes.root}`}>
      <h1 className=Styles.utility.srOnly> {React.string("Check.beer")} </h1>
      <h2> {React.string("Přihlášení")} </h2>
      {switch signInEmailSent {
      | Some(email) =>
        <>
          <p>
            {React.string(`Poslali jsme vám odkaz na přihlášení.`)}
            <br />
            {React.string(`Zkontrolujte poštu na adrese `)}
            <b> {React.string(email)} </b>
          </p>
          <p className=classes.small>
            {React.string(`❗️ Může to zapadnout do spamu 🤷‍♂️`)}
          </p>
          <button className={Styles.button.base} onClick={_ => onBackToForm()} type_="button">
            {React.string(`Zpět na přihlášení`)}
          </button>
        </>
      | None =>
        <>
          <Form.Provider value=Some(form)>
            <form onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
              <fieldset className={`reset ${Styles.fieldset.grid}`}>
                {switch isStandaloneModeStatus.data {
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
                <button
                  className={`${Styles.button.base} ${Styles.fieldset.gridSpan}`} type_="submit">
                  {React.string(`Přihlásit se e${HtmlEntities.nbhp}mailem`)}
                </button>
              </fieldset>
            </form>
          </Form.Provider>
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
          <section ariaLabelledby="other_methods">
            <h3 id="other_methods">
              <span> {React.string("nebo")} </span>
            </h3>
            <button className={Styles.button.base} onClick={_ => onGoogleAuth()} type_="button">
              {React.string("Přihlásit se přes Google")}
            </button>
          </section>
        </>
      }}
    </div>
  }
}

let signInWithEmailChecked = ref(false)
let useSignInWithEmailRedirect = auth => {
  React.useEffect0(() => {
    if !signInWithEmailChecked.contents {
      signInWithEmailChecked := true
      let href = Webapi.Dom.location->Webapi.Dom.Location.href
      if Firebase.Auth.isSignInWithEmailLink(. auth, ~href) {
        let email = switch AppStorage.getPendingEmail() {
        | Some(email) => {
            AppStorage.removePendingEmail()
            email
          }
        | None => Webapi.Dom.Window.prompt(window, "Zadejte svůj e-mail")
        }
        Firebase.Auth.signInWithEmailLink(. auth, ~email, ~href)
        ->Promise.then(_ => {
          AppStorage.removePendingEmail()
          if AppStorage.getThrustDevice()->Option.isSome {
            AppStorage.setRememberEmail(email)
          }
          let hrefWOParams = RouterUtils.truncateQueryString(href)
          Webapi.Dom.location->Webapi.Dom.Location.setHref(hrefWOParams)
          Promise.resolve()
        })
        ->ignore
      }
    }
    None
  })
}

@react.component
let make = () => {
  open Firebase.Auth
  let auth = Reactfire.useAuth()
  let (signInEmailSent, setSignInEmailSent) = React.useState(() => None)
  useSignInWithEmailRedirect(auth)

  <Pure
    initialEmail={AppStorage.getRememberEmail()->Option.getWithDefault("")}
    onBackToForm={() => setSignInEmailSent(_ => None)}
    onGoogleAuth={() => {
      signInWithPopup(. auth, FederatedAuthProvider.googleAuthProvider())
      ->Promise.catch(error => {
        Js.log(error)
        Promise.reject(error)
      })
      ->ignore
    }}
    onPasswordAuth={async ({email}) => {
      let href = Webapi.Dom.location->Webapi.Dom.Location.href
      let _ = await sendSignInLinkToEmail(.
        auth,
        ~email,
        ~actionCodeSettings={
          url: href,
          handleCodeInApp: true,
        },
      )
      AppStorage.setPendingEmail(email)
      setSignInEmailSent(_ => Some(email))
    }}
    ?signInEmailSent
  />
}
