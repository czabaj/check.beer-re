let smallBeerInMilliliters = 300
let largeBeerInMilliliters = 500

let getFormatConsumption = (
  consumptionSymbols: Js.nullable<FirestoreModels.consumptionSymbols>,
) => {
  let symbolMap = consumptionSymbols->Nullable.getOr({"300": "I", "500": "X"})
  (consumption: Db.userConsumption) => {
    consumption.milliliters < 400 ? symbolMap["300"] : symbolMap["500"]
  }
}
