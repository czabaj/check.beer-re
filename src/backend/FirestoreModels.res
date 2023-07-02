type personName = string
type personUID = string
type tapName = string

type userAccount = {
  email: string,
  name: string,
  places: Js.Dict.t<string>,
}

type rec consumption = {
  createdAt: Firebase.Timestamp.t,
  milliliters: int,
  person: Firebase.documentReference<person>,
}
and keg = {
  beer: string,
  consumptions: array<consumption>,
  createdAt: Firebase.Timestamp.t,
  depletedAt: Null.t<Firebase.Timestamp.t>,
  milliliters: int,
  priceEnd: Null.t<int>,
  priceNew: int,
  recentConsumptionAt: Null.t<Firebase.Timestamp.t>,
  serial: int,
}
and financialTransaction = {
  amount: int,
  createdAt: Firebase.Timestamp.t,
  keg: Null.t<Firebase.documentReference<keg>>,
  note: Null.t<string>,
}
and person = {
  account: Null.t<Firebase.documentReference<userAccount>>,
  balance: int,
  createdAt: Firebase.Timestamp.t,
  name: personName,
  transactions: array<financialTransaction>,
}

type personsAllItem = (personName, Firebase.Timestamp.t, Null.t<tapName>)

type place = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Js.Dict.t<personsAllItem>,
  // null means the tap is not in use, undefined would remove the key
  taps: Js.Dict.t<Js.null<Firebase.documentReference<keg>>>,
}
