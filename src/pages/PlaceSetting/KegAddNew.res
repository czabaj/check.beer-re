module FormFields = %lenses(type state = {beer: string, liters: int, price: int, serial: int})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

module FormComponent = {
  @react.component
  let make = (~onSubmit, ~placeId) => {
    let mostRecentKegStatus = Db.useMostRecentKegStatus(placeId)
    switch mostRecentKegStatus.data {
    | None => React.null
    | Some(mostResentKegs) => {
        let emptyState: FormFields.state = {beer: "", liters: 30, price: 0, serial: 1}
        let recentKegState =
          mostResentKegs
          ->Belt.Array.get(0)
          ->Belt.Option.mapWithDefault(emptyState, keg => {
            let {beer, milliliters, priceNew, serial} = keg
            {beer, liters: milliliters / 1000, price: priceNew, serial: serial + 1}
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
            open Validators
            schema([
              required(Beer),
              int(~min=1, ~minError="Sud nemůže být nulový", Liters),
              int(~min=0, ~minError="Cena nemůže být záporná", Price),
            ])
          },
          ~validationStrategy=OnDemand,
          (),
        )

        <Form.Provider value=Some(form)>
          <form id="addKeg" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
            <fieldset>
              <Form.Field
                field=Beer
                render={field => {
                  <>
                    <label htmlFor="beer"> {React.string("Pivo")} </label>
                    <input
                      id="beer"
                      name="beer"
                      onChange={ReForm.Helpers.handleChange(field.handleChange)}
                      type_="text"
                      value={field.value}
                    />
                    {switch field.error {
                    | Some(error) => React.string(error)
                    | None => React.null
                    }}
                  </>
                }}
              />
              <Form.Field
                field=Liters
                render={field => {
                  <>
                    <label htmlFor="liters"> {React.string("Objem sudu")} </label>
                    <input
                      id="liters"
                      max="200"
                      min="1"
                      name="liters"
                      onChange={event =>
                        field.handleChange(ReactEvent.Form.target(event)["valueAsNumber"])}
                      step=1.0
                      type_="number"
                      value={field.value->Int.toString}
                    />
                    {switch field.error {
                    | Some(error) => React.string(error)
                    | None => React.null
                    }}
                  </>
                }}
              />
              <Form.Field
                field=Price
                render={field => {
                  <>
                    <label htmlFor="price"> {React.string("Cena sudu")} </label>
                    <input
                      id="price"
                      min="0"
                      name="price"
                      onChange={event =>
                        field.handleChange(ReactEvent.Form.target(event)["valueAsNumber"])}
                      step=1.0
                      type_="number"
                      value={field.value->Int.toString}
                    />
                    {switch field.error {
                    | Some(error) => React.string(error)
                    | None => React.null
                    }}
                  </>
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
