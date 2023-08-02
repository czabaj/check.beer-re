module FormFields = %lenses(type state = {role: UserRoles.role})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~currentRole, ~onDismiss, ~onSubmit, ~personName) => {
  open UserRoles
  let roleOptions = [Viewer, SelfService, Staff, Admin]
  let form = Form.use(
    ~initialState={role: currentRole},
    ~onSubmit=({state}) => {
      onSubmit(state.values)
      None
    },
    ~schema={
      Validators.schema([])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <DialogForm formId="change_role" heading="Změnit roli" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <p>
        <b> {personName->React.string} </b>
        {React.string(" je aktuálně ")}
        <b> {currentRole->roleI18n->React.string} </b>
      </p>
      <form id="change_role" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
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
                labelSlot={React.string("Nová role")}
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
