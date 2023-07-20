module FormFields = %lenses(
  type state = {
    beer: string,
    donors: Js.Dict.t<int>,
    milliliters: int,
    price: int,
    serial: int,
  }
)

let emptyState: FormFields.state = {
  beer: "",
  donors: Js.Dict.empty(),
  milliliters: 0,
  price: 0,
  serial: 1,
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

let getSelectedOption: {..} => array<
  string,
> = %raw(`select => Array.from(select.selectedOptions, option => option.value)`)

module FormComponent = {
  @react.component
  let make = (~onSubmit, ~personsAll: array<(string, Db.personsAllRecord)>, ~placeId) => {
    let personsAllNames = React.useMemo1(
      () => personsAll->Array.map(((_, {name})) => name),
      [personsAll],
    )
    let personsAllMap = React.useMemo1(() => personsAll->Js.Dict.fromArray, [personsAll])
    let {minorUnit} = FormattedCurrency.useCurrency()
    let mostRecentKegStatus = Db.useMostRecentKegStatus(placeId)
    switch mostRecentKegStatus.data {
    | None => React.null
    | Some(mostResentKegs) => {
        let recentKegState =
          mostResentKegs
          ->Array.at(0)
          ->Option.mapWithDefault(emptyState, keg => {
            let {beer, donors, milliliters, price, serial} = keg
            {
              beer,
              donors,
              milliliters,
              price,
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
            Validators.schema([
              Validators.required(Beer),
              Validators.int(~min=1, ~minError="Sud nemůže být nulový", Milliliters),
              Validators.int(~min=0, ~minError="Cena nemůže být záporná", Price),
              Validators.custom(lensState => {
                let donorsSum = lensState.donors->Js.Dict.values->Array.reduce(0, (a, b) => a + b)
                let kegPrice = lensState.price
                if kegPrice > 0 && kegPrice != donorsSum {
                  Error("Cena sudu se neshoduje s příspěvky vkladatelů")
                } else {
                  Valid
                }
              }, Donors),
            ])
          },
          ~validationStrategy=OnDemand,
          (),
        )

        <Form.Provider value=Some(form)>
          <form id="add_keg" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
            <fieldset className={`reset ${Styles.fieldset.grid}`}>
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
                field=Milliliters
                render={field => {
                  <InputWrapper
                    inputError=?field.error
                    inputName="liters"
                    inputSlot={<input
                      max="200"
                      min="1"
                      onChange={event =>
                        field.handleChange(ReactEvent.Form.target(event)["valueAsNumber"] * 1000)}
                      step=1.0
                      type_="number"
                      value={(field.value->Float.fromInt /. 1000.0)->Float.toString}
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
                        field.handleChange(
                          (ReactEvent.Form.target(event)["valueAsNumber"] *. minorUnit)
                            ->Int.fromFloat,
                        )}
                      step=1.0
                      type_="number"
                      value={(field.value->Float.fromInt /. minorUnit)->Float.toString}
                    />}
                    labelSlot={React.string("Cena sudu")}
                  />
                }}
              />
            </fieldset>
            <Form.Field
              field=Donors
              render={field => {
                <InputDonors
                  errorMessage=?field.error
                  legendSlot={React.string("Vkladatelé sudu")}
                  onChange={field.handleChange}
                  persons=personsAllNames
                  value={field.value}
                />
              }}
            />
          </form>
        </Form.Provider>
      }
    }
  }
}

@react.component
let make = (~onDismiss, ~onSubmit, ~personsAll, ~placeId) => {
  <DialogForm formId="add_keg" heading="Přidat sud" onDismiss visible=true>
    <React.Suspense fallback={React.string("Načítám")}>
      <FormComponent onSubmit personsAll placeId />
    </React.Suspense>
  </DialogForm>
}
