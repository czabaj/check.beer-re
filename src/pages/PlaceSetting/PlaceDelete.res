type classesType = {root: string}

@module("./PlaceDelete.module.css") external classes: classesType = "default"

module FormFields = {
  type state = {name: string}
  type rec field<_> = Name: field<string>
  let get:
    type value. (state, field<value>) => value =
    (state, field) =>
      switch field {
      | Name => state.name
      }
  let set:
    type value. (state, field<value>, value) => state =
    (_state, field, value) =>
      switch field {
      | Name => {name: value}
      }
}

module Form = ReForm.Make(FormFields)
module Validators = Validators.CustomValidators(FormFields)

@react.component
let make = (~onConfirm, ~onDismiss, ~placeName) => {
  let form = Form.use(
    ~initialState={name: ""},
    ~onSubmit=_ => {
      onConfirm()
      None
    },
    ~validationStrategy=OnDemand,
    ~schema={
      Validators.schema([
        Validators.required(Name),
        Validators.equals(~expected=placeName, ~error="Jméno místa se neshoduje", Name),
      ])
    },
    (),
  )
  <DialogForm
    className=classes.root
    formId="place_delete"
    heading="Odstranění místa"
    onDismiss={onDismiss}
    visible=true>
    <Form.Provider value=Some(form)>
      <p> {React.string(`Pokud si přejete smazat místo, napište jeho název a potvrďte. `)} </p>
      <p className={Styles.messageBar.variantDanger} role="alert">
        <strong> {React.string(`Smazání místa je nevratná operace!`)} </strong>
        {React.string(` Tímto ztratíte veškeré údaje o místu a nepůjdou vrátit zpět`)}
      </p>
      <form id="place_delete" onSubmit={ReForm__Helpers.handleSubmit(form.submit)}>
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
        </fieldset>
      </form>
    </Form.Provider>
  </DialogForm>
}
