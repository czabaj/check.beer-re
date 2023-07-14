type classesType = {root: string}

@module("./Unauthenticated.module.css") external classes: classesType = "default"

module UnauthenticatedStorage = {
  open Dom.Storage2

  let keyRememeberedEmail = "Unauthenticated.email"
  let keyPendingEmail = "Unauthenticated.email_pending"

  let getPendingEmail = () => localStorage->getItem(keyPendingEmail)
  let setPendingEmail = email => localStorage->setItem(keyPendingEmail, email)
  let removePendingEmail = () => localStorage->removeItem(keyPendingEmail)
  let getRememberEmail = () => localStorage->getItem(keyRememeberedEmail)
  let setRememberEmail = email => localStorage->setItem(keyRememeberedEmail, email)
}

module UnauthenticatedQueryString = {
  open Webapi

  let keyRemember = "r"

  let isRememberOn = href => {
    let rememberParam =
      Url.make(href)
      ->Url.searchParams
      ->Url.URLSearchParams.get(keyRemember)
      ->Option.getWithDefault("0")
    rememberParam === "1"
  }
  let setRememberOn = href => {
    let url = Url.make(href)
    url->Url.setSearch(`${keyRemember}=1`)
    url->Url.href
  }
}

module FormFields = %lenses(type state = {email: string, remember: bool})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

module Pure = {
  @react.component
  let make = (~initialEmail, ~onBackToForm, ~onGoogleAuth, ~onPasswordAuth, ~signInEmailSent=?) => {
    let form = Form.use(
      ~initialState={email: initialEmail, remember: initialEmail !== ""},
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
            {React.string(`Zkontrolujte schránku `)}
            <b> {React.string(email)} </b>
          </p>
          <button className={Styles.button.button} onClick={_ => onBackToForm()} type_="button">
            {React.string(`Zpět na přihlášení`)}
          </button>
        </>
      | None =>
        <>
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
                  field=Remember
                  render={field => {
                    <label className=Styles.fieldset.gridSpan>
                      {React.string(`Zapamatovat si e${HtmlEntities.nbhp}mail`)}
                      <input
                        checked={field.value}
                        onChange={event => {
                          let target = event->ReactEvent.Form.target
                          field.handleChange(target["checked"])
                        }}
                        type_="checkbox"
                      />
                    </label>
                  }}
                />
                <button
                  className={`${Styles.button.button} ${Styles.fieldset.gridSpan}`} type_="submit">
                  {React.string(`Přihlásit se e${HtmlEntities.nbhp}mailem`)}
                </button>
              </fieldset>
            </form>
          </Form.Provider>
          <section ariaLabelledby="other_methods">
            <h3 id="other_methods">
              <span> {React.string("nebo")} </span>
            </h3>
            <button className={Styles.button.button} onClick={_ => onGoogleAuth()} type_="button">
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
      let remember = ref(false)
      if Firebase.Auth.isSignInWithEmailLink(. auth, ~href) {
        let email = switch UnauthenticatedStorage.getPendingEmail() {
        | Some(email) => {
            UnauthenticatedStorage.removePendingEmail()
            remember := UnauthenticatedQueryString.isRememberOn(href)
            email
          }
        | None => Webapi.Dom.Window.prompt(window, "Zadejte svůj e-mail")
        }
        Firebase.Auth.signInWithEmailLink(. auth, ~email, ~href)
        ->Promise.then(_ => {
          UnauthenticatedStorage.removePendingEmail()
          if remember.contents {
            UnauthenticatedStorage.setRememberEmail(email)
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
    initialEmail={UnauthenticatedStorage.getRememberEmail()->Option.getWithDefault("")}
    onBackToForm={() => setSignInEmailSent(_ => None)}
    onGoogleAuth={() => {
      signInWithPopup(. auth, FederatedAuthProvider.googleAuthProvider())
      ->Promise.catch(error => {
        Js.log(error)
        Promise.reject(error)
      })
      ->ignore
    }}
    onPasswordAuth={async ({email, remember}) => {
      let href = Webapi.Dom.location->Webapi.Dom.Location.href
      let _ = await sendSignInLinkToEmail(.
        auth,
        ~email,
        ~actionCodeSettings={
          url: remember ? UnauthenticatedQueryString.setRememberOn(href) : href,
          handleCodeInApp: true,
        },
      )
      UnauthenticatedStorage.setPendingEmail(email)
      setSignInEmailSent(_ => Some(email))
    }}
    ?signInEmailSent
  />
}
