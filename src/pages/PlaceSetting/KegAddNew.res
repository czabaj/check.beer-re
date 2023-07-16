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
  milliliters: 30,
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
  let make = (~onSubmit, ~place: Db.placeConverted, ~placeId) => {
    let {minorUnit} = FormattedCurrency.useCurrency()
    let mostRecentKegStatus = Db.useMostRecentKegStatus(placeId)
    switch mostRecentKegStatus.data {
    | None => React.null
    | Some(mostResentKegs) => {
        let recentKegState =
          mostResentKegs
          ->Belt.Array.get(0)
          ->Belt.Option.mapWithDefault(emptyState, keg => {
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
            <fieldset className="reset">
              <legend> {React.string("Vkladatelé sudu")} </legend>
              <Form.Field
                field=Donors
                render={field => {
                  let value = field.value
                  <>
                    <InputWrapper
                      inputError=?field.error
                      inputName="donors_select"
                      inputSlot={<select
                        multiple=true
                        onChange={event => {
                          let target = event->ReactEvent.Form.target
                          let newValue =
                            getSelectedOption(target)
                            ->Array.map(personId => (
                              personId,
                              value->Js.Dict.get(personId)->Option.getWithDefault(0),
                            ))
                            ->Js.Dict.fromArray
                          field.handleChange(newValue)
                        }}
                        value={value->Js.Dict.keys->TypeUtils.any}>
                        {place.personsAll
                        ->Js.Dict.entries
                        ->Array.map(((personId, person)) =>
                          <option key={personId} value={personId}>
                            {React.string(person.name)}
                          </option>
                        )
                        ->React.array}
                      </select>}
                      labelSlot={React.null}
                    />
                    <ul className="reset">
                      {value
                      ->Js.Dict.entries
                      ->Array.map(((personId, amount)) => {
                        let person = place.personsAll->Js.Dict.get(personId)->Option.getExn
                        <li key=personId>
                          {React.string(person.name)}
                          <input
                            onChange={event => {
                              let target = event->ReactEvent.Form.target
                              let newValue = ObjectUtils.setInD(
                                value,
                                personId,
                                (target["valueAsNumber"] *. minorUnit)->Int.fromFloat,
                              )
                              field.handleChange(newValue)
                            }}
                            min="0"
                            step=1.0
                            max={(form.values.price->Float.fromInt /. minorUnit)->Float.toString}
                            type_="number"
                            value={(amount->Float.fromInt /. minorUnit)->Float.toString}
                          />
                        </li>
                      })
                      ->React.array}
                    </ul>
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
let make = (~onDismiss, ~onSubmit, ~place, ~placeId) => {
  <DialogForm formId="add_keg" heading="Přidat sud" onDismiss visible=true>
    <React.Suspense fallback={React.string("Načítám")}>
      <FormComponent onSubmit place placeId />
    </React.Suspense>
  </DialogForm>
}
