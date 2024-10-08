module FormFields = {
  type state = {role: UserRoles.role}
  type rec field<_> = Role: field<UserRoles.role>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Role => state.role
      }
  let set:
    type value. (state, field<value>, value) => state =
    (_state, field, value) =>
      switch field {
      | Role => {role: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~onDismiss, ~onSubmit) => {
  open UserRoles
  let roleOptions = [Viewer, SelfService, Staff, Admin]
  let form = Form.use(
    ~initialState={role: Viewer},
    ~onSubmit=({state}) => {
      onSubmit(state.values)->ignore
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
                    let role =
                      roleString->Int.fromString->Option.flatMap(roleFromInt)->Option.getExn
                    field.handleChange(role)
                  }}
                  value={(field.value :> int)->Int.toString}>
                  {roleOptions
                  ->Array.map(role => {
                    let label = role->roleI18n
                    let value = (role :> int)->Int.toString
                    <option key={value} value={value}> {React.string(label)} </option>
                  })
                  ->React.array}
                </select>}
                labelSlot={React.string("Role")}
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
      </form>
      <SectionRoleDescription />
    </Form.Provider>
  </DialogForm>
}
