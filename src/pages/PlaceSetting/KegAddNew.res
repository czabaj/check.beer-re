module FormFields = %lenses(type state = {beer: string, liters: float, price: float, serial: int})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

module FormComponent = {
  @react.component
  let make = (~onSubmit, ~placeId) => {
    let currency = FormattedCurrency.useCurrency()
    let mostRecentKegStatus = Db.useMostRecentKegStatus(placeId)
    switch mostRecentKegStatus.data {
    | None => React.null
    | Some(mostResentKegs) => {
        let emptyState: FormFields.state = {beer: "", liters: 30.0, price: 0.0, serial: 1}
        let recentKegState =
          mostResentKegs
          ->Belt.Array.get(0)
          ->Belt.Option.mapWithDefault(emptyState, keg => {
            let {beer, milliliters, price, serial} = keg
            {
              beer,
              liters: milliliters->Float.fromInt /. 1000.0,
              price: price->Float.fromInt /. currency.minorUnit,
              serial: serial + 1,
            }
          })
        let form = Form.use(
          ~initialState={recentKegState},
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
            open! Validators
            schema([
              required(Beer),
              float(~min=1.0, ~minError="Sud nemůže být nulový", Liters),
              float(~min=0.0, ~minError="Cena nemůže být záporná", Price),
            ])
          },
          ~validationStrategy=OnDemand,
          (),
        )

        <Form.Provider value=Some(form)>
          <form id="addKeg" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
            <fieldset className={`reset ${Styles.fieldsetClasses.grid}`}>
              <Form.Field
                field=Beer
                render={field => {
                  <InputWrapper
                    inputError=?field.error
                    inputName="beer"
                    inputSlot={<input
                      onChange={ReForm.Helpers.handleChange(field.handleChange)}
                      type_="text"
                      value={field.value}
                    />}
                    labelSlot={React.string("Pivo")}
                  />
                }}
              />
              <Form.Field
                field=Liters
                render={field => {
                  <InputWrapper
                    inputError=?field.error
                    inputName="liters"
                    inputSlot={<input
                      max="200"
                      min="1"
                      onChange={event =>
                        field.handleChange(ReactEvent.Form.target(event)["valueAsNumber"])}
                      step=1.0
                      type_="number"
                      value={field.value->Float.toString}
                    />}
                    labelSlot={React.string("Objem sudu")}
                  />
                }}
              />
              <Form.Field
                field=Price
                render={field => {
                  <InputWrapper
                    inputError=?field.error
                    inputName="price"
                    inputSlot={<input
                      min="0"
                      onChange={event =>
                        field.handleChange(ReactEvent.Form.target(event)["valueAsNumber"])}
                      step=1.0
                      type_="number"
                      value={field.value->Float.toString}
                    />}
                    labelSlot={React.string("Cena sudu")}
                  />
                }}
              />
            </fieldset>
          </form>
        </Form.Provider>
      }
    }
  }
}

@react.component
let make = (~onDismiss, ~onSubmit, ~placeId) => {
  <DialogForm formId="addKeg" heading="Přidat sud" onDismiss visible=true>
    <React.Suspense fallback={React.string("Načítám")}>
      <FormComponent onSubmit placeId />
    </React.Suspense>
  </DialogForm>
}
