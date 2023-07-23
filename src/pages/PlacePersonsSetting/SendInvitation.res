module FormFields = %lenses(type state = {role: FirestoreModels.role})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~onDismiss, ~onSubmit) => {
  open FirestoreModels
  let roleOptions = [Viewer, SelfService, Staff, Admin]
  let form = Form.use(
    ~initialState={role: Viewer},
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
      Validators.schema([])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <DialogForm formId="send_invitation" heading="Poslat pozvánku" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="send_invitation" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className="reset">
          <Form.Field
            field=Role
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="role"
                inputSlot={<select
                  onChange={event => {
                    let roleString = ReactEvent.Form.target(event)["value"]
                    let role = roleString->Int.fromString->Option.flatMap(roleFromJs)->Option.getExn
                    field.handleChange(role)
                  }}
                  value={field.value->roleToJs->Int.toString}>
                  {roleOptions
                  ->Array.map(role => {
                    let label = role->roleI18n
                    let value = role->roleToJs->Int.toString
                    <option key={value} value={value}> {React.string(label)} </option>
                  })
                  ->React.array}
                </select>}
                labelSlot={React.string("Role")}
              />
            }}
          />
        </fieldset>
      </form>
      <section ariaLabelledby="role_description">
        <h3 id="role_description"> {React.string("Popis rolí")} </h3>
        <ol className="reset">
          {roleOptions
          ->Array.map(role => {
            let name = role->FirestoreModels.roleI18n
            <li key=name>
              <b> {React.string(name)} </b>
              {React.string(` - ${role->FirestoreModels.roleDescription}`)}
            </li>
          })
          ->React.array}
        </ol>
      </section>
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
  </DialogForm>
}
