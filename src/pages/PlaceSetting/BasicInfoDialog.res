module FormFields = %lenses(
  type state = {
    createdAt: string,
    name: string,
  }
)

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

type dialogState = Hidden | PlaceDelete

@react.component
let make = (~initialValues, ~onDismiss, ~onPlaceDelete, ~onSubmit) => {
  let form = Form.use(
    ~initialState=initialValues,
    ~onSubmit=({state}) => {
      onSubmit(state.values)
      None
    },
    ~validationStrategy=OnDemand,
    ~schema={
      open Validators
      schema([required(Name), required(CreatedAt)])
    },
    (),
  )
  let (dialogState, setDialog) = React.useState(() => Hidden)

  <>
    <DialogForm formId="basic_info" heading="Základní údaje místa" onDismiss visible=true>
      <Form.Provider value=Some(form)>
        <form id="basic_info" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
          <fieldset className={`reset ${Styles.fieldset.grid}`}>
            <Form.Field
              field=Name
              render={field => {
                <InputWrapper
                  inputError=?field.error
                  inputName="name"
                  inputSlot={<input
                    onChange={ReForm.Helpers.handleChange(field.handleChange)}
                    type_="text"
                    value={field.value}
                  />}
                  labelSlot={React.string("Název")}
                />
              }}
            />
            <Form.Field
              field=CreatedAt
              render={field => {
                <InputWrapper
                  inputError=?field.error
                  inputName="created"
                  inputSlot={<input
                    onChange={ReForm.Helpers.handleChange(field.handleChange)}
                    type_="date"
                    value={field.value}
                  />}
                  labelSlot={React.string("Založeno")}
                />
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
        <div>
          <button
            className={Styles.button.variantDanger}
            onClick={_ => setDialog(_ => PlaceDelete)}
            type_="button">
            {React.string("Smazat místo")}
          </button>
        </div>
      </Form.Provider>
    </DialogForm>
    {switch dialogState {
    | Hidden => React.null
    | PlaceDelete =>
      <PlaceDelete
        onDismiss={() => setDialog(_ => Hidden)}
        onConfirm=onPlaceDelete
        placeName=initialValues.name
      />
    }}
  </>
}
