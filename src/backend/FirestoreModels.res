type personName = string
type personUID = string
type tapName = string

@genType
type userAccount = {
  email: string,
  name: string,
  places: Js.Dict.t<string>,
}

@genType
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
  milliliters: int,
  price: int,
  recentConsumptionAt: Js.null<Firebase.Timestamp.t>,
  serial: int,
}
@genType
and financialTransaction = {
  amount: int,
  createdAt: Firebase.Timestamp.t,
  keg: Js.null<Firebase.documentReference<keg>>,
  note: Js.null<string>,
}
@genType
and person = {
  account: Js.null<Firebase.documentReference<userAccount>>,
  createdAt: Firebase.Timestamp.t,
  name: personName,
  transactions: array<financialTransaction>,
}

type personsAllItem = (personName, Firebase.Timestamp.t, int, option<tapName>)

@genType
type place = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Js.Dict.t<personsAllItem>,
  // null means the tap is not in use, undefined would remove the key
  taps: Js.Dict.t<Js.null<Firebase.documentReference<keg>>>,
}
