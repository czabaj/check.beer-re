type classesType = {fieldset: string}

@module("./BasicInfoDialog.module.css") external classes: classesType = "default"

module FormFields = %lenses(
  type state = {
    createdAt: string,
    name: string,
  }
)

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~initialValues, ~onDismiss, ~onSubmit) => {
  let form = Form.use(
    ~initialState=initialValues,
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
    ~validationStrategy=OnDemand,
    ~schema={
      open Validators
      schema([required(Name)])
    },
    (),
  )

  <DialogForm formId="basicInfo" heading="Základní údaje místa" onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="basicInfo" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${classes.fieldset}`}>
          <Form.Field
            field=Name
            render={field => {
              <>
                <label htmlFor="name"> {React.string("Název")} </label>
                <input
                  id="name"
                  name="name"
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />
                {switch Field(Name)->form.getFieldError {
                | None => React.null
                | Some(message) => React.string(message)
                }}
              </>
            }}
          />
          <Form.Field
            field=CreatedAt
            render={field => {
              <>
                <label htmlFor="created"> {React.string("Založeno")} </label>
                <input
                  id="created"
                  name="created"
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="date"
                  value={field.value}
                />
              </>
            }}
          />
        </fieldset>
      </form>
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
