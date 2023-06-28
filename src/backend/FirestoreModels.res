type personName = string
type personUID = string
type tapName = string

type personShort = {
  id: personUID,
  lastUpdateAt: Firebase.Timestamp.t,
  name: personName,
  preferredTap?: tapName,
}

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
  depletedAt?: Firebase.Timestamp.t,
  lastConsumptionAt?: Firebase.Timestamp.t,
  milliliters: int,
  priceEnd?: int,
  priceNew: int,
  serial: int,
}
and financialTransaction = {
  amount: int,
  createdAt: Firebase.Timestamp.t,
  keg?: Firebase.documentReference<keg>,
  note?: string,
}
and person = {
  account?: Firebase.documentReference<userAccount>,
  balance: int,
  createdAt: Firebase.Timestamp.t,
  name: personName,
  transactions: array<financialTransaction>,
}

type place = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // the key is the person's UUID
  personsAll: Js.Dict.t<(personName, Firebase.Timestamp.t, option<tapName>)>,
  // null means the tap is not in use, undefined would remove the key
  taps: Js.Dict.t<Js.nullable<Firebase.documentReference<keg>>>,
}
