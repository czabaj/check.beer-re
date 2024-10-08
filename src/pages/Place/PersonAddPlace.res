type classesType = {root: string}

@module("./PersonAddPlace.module.css") external classes: classesType = "default"

module FormFields = {
  type state = {name: string}
  type rec field<_> = Name: field<string>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Name => state.name
      }
  let set:
    type value. (state, field<value>, value) => state =
    (_state, field, value) =>
      switch field {
      | Name => {name: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~existingActive, ~existingInactive, ~onDismiss, ~onMoveToActive, ~onSubmit) => {
  let form = Form.use(
    ~initialState={name: ""},
    ~onSubmit=({state}) => {
      onSubmit(state.values)->ignore
      None
    },
    ~schema={
      open Validators
      schema([
        required(Name),
        notIn(~haystack=existingActive, ~error="Takové jméno již evidujeme", Name),
        notIn(~haystack=existingInactive, ~error="Takové jméno již evidujeme", Name),
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  let datalist = React.useMemo2(() => {
    <datalist id="inactiveNames">
      {existingInactive->Array.map(name => <option key={name} value={name} />)->React.array}
    </datalist>
  }, (existingActive, existingInactive))
  <DialogForm
    className={classes.root} formId="addPerson" heading="Nový host" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="addPerson" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className="reset">
          <Form.Field
            field=Name
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="name"
                inputSlot={<>
                  <input
                    list="inactiveNames"
                    onChange={ReForm.Helpers.handleChange(field.handleChange)}
                    type_="text"
                    value={field.value}
                  />
                  {datalist}
                </>}
                labelSlot={React.string("Jméno")}
              />
            }}
          />
        </fieldset>
      </form>
      <Form.Field
        field=Name
        render={field => {
          let name = field.value
          existingInactive->Array.includes(name)
            ? <p>
                {React.string("Toto jméno evidujeme u osob v nepřítomnosti, můžete ")}
                <button
                  className={Styles.link.base} onClick={_ => onMoveToActive(name)} type_="button">
                  {React.string("přenést tuto osobu do pivního zápisníku")}
                </button>
                {React.string(".")}
              </p>
            : React.null
        }}
      />
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
