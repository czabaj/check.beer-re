type submitValues = {oldPassword: string, newPassword: string}

module FormFields = %lenses(
  type state = {newPassword: string, newPasswordConfirmation: string, oldPassword: string}
)

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~onDismiss, ~onSubmit) => {
  let form = Form.use(
    ~initialState={newPassword: "", newPasswordConfirmation: "", oldPassword: ""},
    ~onSubmit=({raiseSubmitFailed, send, state}) => {
      let {newPassword, oldPassword} = state.values
      onSubmit({newPassword, oldPassword})
      ->Promise.catch(error => {
        switch FirebaseError.toFirebaseError(error) {
        | FirebaseError.InvalidPassword => {
            let oldPasswordField = Form.ReSchema.Field(OldPassword)
            let newFieldsState = state.fieldsState->Array.map(((field, _) as tuple) => {
              field != oldPasswordField ? tuple : (field, ReForm.Error(`Nesprávné heslo`))
            })
            send(SetFieldsState(newFieldsState))
          }
        | _ =>
          let exn = Js.Exn.asJsExn(error)->Option.getExn
          LogUtils.captureException(exn)
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
      Validators.schema([
        Validators.required(OldPassword),
        Validators.required(NewPassword),
        Validators.password(NewPassword),
        Validators.matchField(
          ~error="Hesla se neshodují",
          ~secondField=NewPassword,
          NewPasswordConfirmation,
        ),
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  let submitting = form.state.formState == Submitting
  <DialogForm formId="change_password" heading="Změna hesla" onDismiss visible=true>
    <Form.Provider value={Some(form)}>
      <form
        className={Styles.stack.base}
        id="change_password"
        onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`} disabled={submitting}>
          <Form.Field
            field=OldPassword
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="oldPassword"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="password"
                  value={field.value}
                />}
                labelSlot={React.string(`Nynější heslo`)}
              />
            }}
          />
          <Form.Field
            field=NewPassword
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="newPassword"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="password"
                  value={field.value}
                />}
                labelSlot={React.string(`Nové heslo`)}
              />
            }}
          />
          <Form.Field
            field=NewPasswordConfirmation
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="newPasswordConfirmation"
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
        | SubmitFailed(maybeErrorMessage) =>
          <p className={Styles.messageBar.variantDanger}>
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
      </form>
    </Form.Provider>
  </DialogForm>
}
