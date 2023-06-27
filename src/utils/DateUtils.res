let toIsoDateString = date => date->Js.Date.toISOString->String.substring(~start=0, ~end=10)

let dateIsoRe = %re("/^\d{4,4}-\d{2,2}-\d{2,2}$/")
let fromIsoDateString = isoDateString => {
  switch dateIsoRe->Js.Re.test_(isoDateString) {
  | true => `${isoDateString}T00:00`->Js.Date.fromString
  | false => raise(Invalid_argument("fromIsoDateString"))
  }
}
