let smallBeerInMilliliters = 300
let largeBeerInMilliliters = 500

@genType
let getFormatConsumption = (
  consumptionSymbols: Js.nullable<FirestoreModels.consumptionSymbols>,
) => {
  let symbolMap = consumptionSymbols->Nullable.getOr({"300": "I", "500": "X"})
  (consumptionMilliliters) => {
    consumptionMilliliters < 400 ? symbolMap["300"] : symbolMap["500"]
  }
}
