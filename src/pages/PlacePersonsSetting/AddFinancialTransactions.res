type submitValues = {amount: int, note: string, person: string}

module FormFields = {
  type state = {amount: string, note: string, person: string}
  type rec field<_> = Amount: field<string> | Note: field<string> | Person: field<string>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Amount => state.amount
      | Note => state.note
      | Person => state.person
      }
  let set:
    type value. (state, field<value>, value) => state =
    (state, field, value) =>
      switch field {
      | Amount => {...state, amount: value}
      | Note => {...state, note: value}
      | Person => {...state, person: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (
  ~initialCounterParty,
  ~onDismiss,
  ~onSubmit,
  ~personId,
  ~personName,
  ~personsAll: array<(string, Db.personsAllRecord)>,
) => {
  let {minorUnit} = FormattedCurrency.useCurrency()
  let form = Form.use(
    ~initialState={amount: "", note: "", person: initialCounterParty},
    ~onSubmit=({state}) => {
      let amountFloat = state.values.amount->Float.fromString->Option.getExn
      let amountMinor = amountFloat *. minorUnit
      onSubmit({
        amount: amountMinor->Int.fromFloat,
        note: state.values.note,
        person: state.values.person,
      })->ignore
      None
    },
    ~schema={
      Validators.schema([
        Validators.required(Amount),
        Validators.isNumeric(Amount),
        Validators.required(Person),
      ])
    },
    ~validationStrategy=OnDemand,
    (),
  )

  <DialogForm
    formId="addFinancialTransaction" heading="Platba mezi účastníky" onDismiss visible=true>
    <p>
      <b> {React.string(personName)} </b>
      {React.string(` předává peníze.`)}
    </p>
    <Form.Provider value=Some(form)>
      <form id="addFinancialTransaction" onSubmit={ReForm.Helpers.handleSubmit(form.submit)}>
        <fieldset className={`reset ${Styles.fieldset.grid}`}>
          <Form.Field
            field=Person
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="amount"
                inputSlot={<select
                  onChange={ReForm.Helpers.handleChange(field.handleChange)} value={field.value}>
                  <option disabled={true} value=""> {React.string("Příjemce platby")} </option>
                  {personsAll
                  ->Belt.Array.keepMap(((pId, p)) =>
                    pId === personId
                      ? None
                      : Some(<option key=pId value=pId> {React.string(p.name)} </option>)
                  )
                  ->React.array}
                </select>}
                labelSlot={React.string("Komu")}
              />
            }}
          />
          <Form.Field
            field=Amount
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="amount"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  step=1.0
                  type_="number"
                  value={field.value}
                />}
                labelSlot={React.string("Částka")}
              />
            }}
          />
          <Form.Field
            field=Note
            render={field => {
              <InputWrapper
                inputError=?field.error
                inputName="note"
                inputSlot={<input
                  onChange={ReForm.Helpers.handleChange(field.handleChange)}
                  type_="text"
                  value={field.value}
                />}
                labelSlot={React.string("Poznámka")}
              />
            }}
          />
        </fieldset>
      </form>
    </Form.Provider>
  </DialogForm>
}
