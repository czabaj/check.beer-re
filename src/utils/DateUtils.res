let hourInSeconds = 3600
let dayInSeconds = 24 * hourInSeconds
let weekInSeconds = 7 * dayInSeconds
let monthInSeconds = 31 * dayInSeconds

@genType
let hourInMilliseconds =
  hourInSeconds * 1000
@genType
let dayInMilliseconds =
  dayInSeconds * 1000
let weekInMilliseconds = weekInSeconds * 1000
@genType
let monthInMilliseconds =
  monthInSeconds * 1000

let toIsoDateString = date => date->Js.Date.toISOString->String.substring(~start=0, ~end=10)

let dateIsoRe = %re("/^\d{4,4}-\d{2,2}-\d{2,2}$/")
let fromIsoDateString = isoDateString => {
  switch dateIsoRe->Js.Re.test_(isoDateString) {
  | true => `${isoDateString}T00:00`->Js.Date.fromString
  | false => raise(Invalid_argument("fromIsoDateString"))
  }
}

let compare = (a, b) => a->Js.Date.getTime -. b->Js.Date.getTime
