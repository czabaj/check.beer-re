module CustomValidators = (Lenses: ReSchema.Lenses) => {
  module ReSchema = ReSchema.Make(Lenses)
  module Validation = ReSchema.Validation

  let custom = Validation.custom

  let email = Validation.email(~error="Neplatný email")

  let float = Validation.float

  let int = Validation.int

  let intNonZero = (~error="Nesmí být nula", field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch value {
      | 0 => Error(error)
      | _ => Valid
      }
    }, field)

  let isNumeric = (~error="Musí být číslo", field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch value->Float.fromString {
      | Some(_) => Valid
      | _ => Error(error)
      }
    }, field)

  let oneOf = (~haystack, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch haystack->Array.includes(value) {
      | true => Valid
      | false => Error(error)
      }
    }, field)

  let notIn = (~haystack, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch haystack->Array.includes(value) {
      | true => Error(error)
      | false => Valid
      }
    }, field)

  let required = Validation.nonEmpty(~error="Bez tohoto to nepůjde")

  let schema = Validation.schema
}
