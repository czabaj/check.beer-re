type personName = string
type personUID = string
type tapName = string

type financialTransaction = {
  amount: int,
  createdAt: Firebase.Timestamp.t,
  keg: Js.null<int>,
  note: Js.null<string>,
}

type rec consumption = {
  milliliters: int,
  person: Firebase.documentReference<person>,
}
@genType
and keg = {
  beer: string,
  consumptions: Js.Dict.t<consumption>,
  createdAt: Firebase.Timestamp.t,
  depletedAt: Js.null<Firebase.Timestamp.t>,
  donors: Js.Dict.t<int>,
  milliliters: int,
  price: int,
  recentConsumptionAt: Js.null<Firebase.Timestamp.t>,
  serial: int,
}
@genType
and person = {
  account: Js.null<string>,
  createdAt: Firebase.Timestamp.t,
  name: personName,
  transactions: array<financialTransaction>,
}

type personsAllItem = (personName, Firebase.Timestamp.t, int, option<tapName>)

@genType.import("./roles") @genType.as("Role") @deriving(jsConverter)
type role =
  | @as(10) Viewer
  | @as(50) Staff
  | @as(80) Admin
  | @as(100) Owner

@genType
type place = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Js.Dict.t<personsAllItem>,
  // null means the tap is not in use, undefined would remove the key
  taps: Js.Dict.t<Js.null<Firebase.documentReference<keg>>>,
  users: Js.Dict.t<int>,
}
