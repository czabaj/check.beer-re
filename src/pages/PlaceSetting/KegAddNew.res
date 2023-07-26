type classesType = {form: string}
@module("./KegAddNew.module.css") external classes: classesType = "default"

module FormFields = %lenses(
  type state = {
    beer: string,
    donors: Js.Dict.t<int>,
    milliliters: int,
    ownerIsDonor: bool,
    price: int,
    serial: int,
  }
)

let emptyState: FormFields.state = {
  beer: "",
  donors: Js.Dict.empty(),
  milliliters: 0,
  ownerIsDonor: true,
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
    let personsAllMap = React.useMemo1(
      () => personsAll->Array.map(((personId, {name})) => (personId, name))->Map.fromArray,
      [personsAll],
    )
    let {currency, minorUnit} = FormattedCurrency.useCurrency()
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
              ownerIsDonor: true,
              price,
              serial: serial + 1,
            }
          })
        let form = Form.use(
          ~initialState={recentKegState},
          ~onSubmit=({state}) => {
            onSubmit(state.values)
            None
          },
          ~schema={
            Validators.schema([
              Validators.required(Beer),
              Validators.int(~min=1, ~minError="Sud nemůže být nulový", Milliliters),
              Validators.int(~min=0, ~minError="Cena nemůže být záporná", Price),
              Validators.custom(lensState => {
                if lensState.ownerIsDonor {
                  Valid
                } else {
                  let donorsSum = lensState.donors->Js.Dict.values->Array.reduce(0, (a, b) => a + b)
                  let kegPrice = lensState.price
                  if kegPrice > 0 && kegPrice != donorsSum {
                    Error("Cena sudu se neshoduje s příspěvky vkladatelů")
                  } else {
                    Valid
                  }
                }
              }, Donors),
            ])
          },
          ~validationStrategy=OnDemand,
          (),
        )

        <Form.Provider value=Some(form)>
          <form
            className={classes.form}
            id="add_keg"
            onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
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
                  let liters = field.value->Float.fromInt /. 1000.0
                  <InputWrapper
                    inputError=?field.error
                    inputName="milliliters"
                    inputSlot={<input
                      max="200"
                      min="1"
                      onChange={event =>
                        field.handleChange(ReactEvent.Form.target(event)["valueAsNumber"] * 1000)}
                      step=1.0
                      type_="number"
                      value={liters->Float.toString}
                    />}
                    labelSlot={React.string("Objem sudu")}
                    unitSlot={<ReactIntl.FormattedPlural
                      one={React.string("Litr")}
                      few={React.string("Litry")}
                      other={React.string("Litrů")}
                      value={liters->Float.toInt}
                    />}
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
                    unitSlot={<ReactIntl.FormattedNumberParts currency style=#currency value={0.}>
                      {(~formattedNumberParts) =>
                        formattedNumberParts
                        ->Array.find(p => p.type_ === `currency`)
                        ->Option.map(p => React.string(p.value))
                        ->Option.getWithDefault(React.null)}
                    </ReactIntl.FormattedNumberParts>}
                  />
                }}
              />
            </fieldset>
            <Form.Field
              field=OwnerIsDonor
              render={field => {
                let ownerIsDonor = field.value
                <>
                  <InputWrapper
                    inputName="owner_is_donor"
                    inputSlot={<InputToggle
                      checked={ownerIsDonor}
                      onChange={event => {
                        let target = event->ReactEvent.Form.target
                        field.handleChange(target["checked"])
                      }}
                    />}
                    labelSlot={React.string("Vkládá vlastník místa")}
                  />
                  {ownerIsDonor
                    ? React.null
                    : <Form.Field
                        field=Donors
                        render={field => {
                          <InputDonors
                            errorMessage=?field.error
                            legendSlot={React.string("Vkladatelé sudu")}
                            onChange={field.handleChange}
                            persons=personsAllMap
                            value={field.value}
                          />
                        }}
                      />}
                </>
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
