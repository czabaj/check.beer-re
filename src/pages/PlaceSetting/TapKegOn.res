module FormFields = %lenses(type state = {keg: string})

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

type selectOption = {text: React.element, value: string}

@react.component
let make = (~onDismiss, ~onSubmit, ~tapName, ~untappedChargedKegs: array<Db.kegConverted>) => {
  let options = untappedChargedKegs->Belt.Array.map(keg => {
    {
      text: <>
        {React.string(`${keg.serialFormatted} ${keg.beer} (`)}
        <FormattedVolume milliliters=keg.milliliters />
        {React.string(")")}
      </>,
      value: Db.getUid(keg),
    }
  })
  let form = Form.use(
    ~initialState={keg: options->Array.get(0)->Option.map(o => o.value)->Option.getWithDefault("")},
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
      schema([required(Keg)])
    },
    ~validationStrategy=OnDemand,
    (),
  )
  <DialogForm formId="tapKegOn" heading={`Narazit pípu: ${tapName}`} onDismiss visible=true>
    <Form.Provider value=Some(form)>
      <form id="tapKegOn" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className="reset">
          <Form.Field
            field=Keg
            render={field => {
              <InputWrapper
                inputName="keg"
                inputSlot={<select
                  onChange={ReForm.Helpers.handleChange(field.handleChange)} value={field.value}>
                  {options
                  ->Array.map(({text, value}) =>
                    <option key={value} value={value}> {text} </option>
                  )
                  ->React.array}
                </select>}
                labelSlot={React.string("Sud")}
              />
            }}
          />
        </fieldset>
      </form>
    </Form.Provider>
  </DialogForm>
}
