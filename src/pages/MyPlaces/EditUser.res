module FormFields = %lenses(type state = {name: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~connectedEmail, ~initialName, ~onDismiss, ~onSubmit) => {
  let isStandaloneModeStatus = DomUtils.useIsStandaloneMode()
  React.useEffect0(() => {
    let initialThrustDevide = AppStorage.getThrustDevice() !== None
    Some(
      () => {
        let unmountThrustDevice = AppStorage.getThrustDevice() !== None
        if initialThrustDevide != unmountThrustDevice {
          // we need to reload the page to re-initialize the Firestore SDK
          open Webapi.Dom
          location->Location.reload
        }
      },
    )
  })
  let form = Form.use(
    ~initialState={name: initialName},
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
      Validators.schema([Validators.required(Name)])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <DialogForm formId="edit_user" heading="Úprava uživatele" onDismiss visible=true>
    <Form.Provider value={Some(form)}>
      <form id="edit_user" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
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
                labelSlot={React.string("Přezdívka")}
              />
            }}
          />
          <InputWrapper
            inputName="email"
            inputSlot={<input disabled=true type_="text" value={connectedEmail} />}
            labelSlot={React.string("E-mail")}
          />
          {switch isStandaloneModeStatus.data {
          | Some(true) => React.null
          | _ => <InputThrustDevice />
          }}
        </fieldset>
      </form>
    </Form.Provider>
  </DialogForm>
}
