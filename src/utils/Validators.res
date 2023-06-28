module CustomValidators = (Lenses: ReSchema.Lenses) => {
  module ReSchema = ReSchema.Make(Lenses)
  module Validation = ReSchema.Validation

  let float = Validation.float

  let int = Validation.int

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
