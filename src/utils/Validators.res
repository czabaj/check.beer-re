module CustomValidators = (Lenses: ReSchema.Lenses) => {
  module ReSchema = ReSchema.Make(Lenses)
  module Validation = ReSchema.Validation

  let custom = Validation.custom

  let email = Validation.email(~error="Neplatný email", ...)

  let equals = (~expected, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      if value == expected {
        Valid
      } else {
        Error(error)
      }
    }, field)

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

  let matchField = (~secondField, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      let secondFieldValue = Lenses.get(lensState, secondField)
      if value == secondFieldValue {
        Valid
      } else {
        Error(error)
      }
    }, field)

  let notIn = (~haystack, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch haystack->Array.includes(value) {
      | true => Error(error)
      | false => Valid
      }
    }, field)

  let oneOf = (~haystack, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch haystack->Array.includes(value) {
      | true => Valid
      | false => Error(error)
      }
    }, field)

  let password = field => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      if value->String.length < 6 {
        Error("Heslo musí mít alespoň 6 znaků")
      } else {
        Valid
      }
    }, field)

  // requires the string to contain at least one non-whitespace character
  let required = Validation.regExp(~error="Bez tohoto to nepůjde", ~matches="[^\s]", ...)

  let schema = Validation.schema
}
