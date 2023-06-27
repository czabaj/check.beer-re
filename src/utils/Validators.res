module CustomValidators = (Lenses: ReSchema.Lenses) => {
  module ReSchema = ReSchema.Make(Lenses)
  module Validation = ReSchema.Validation

  let required = Validation.nonEmpty(~error="Bez tohoto to nepůjde")

  let notIn = (~haystack, ~error, field) => Validation.custom(lensState => {
      let value = Lenses.get(lensState, field)
      switch haystack->Array.includes(value) {
      | true => Error(error)
      | false => Valid
      }
    }, field)

  let schema = Validation.schema
}
