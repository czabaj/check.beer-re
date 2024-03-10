type personName = string
type personUID = string
type tapName = string

type financialTransaction = {
  amount: int,
  createdAt: Firebase.Timestamp.t,
  keg: Js.null<int>,
  note: Js.null<string>,
  person: Js.null<string>,
}

@@warning("-30")
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
  createdAt: Firebase.Timestamp.t,
  transactions: array<financialTransaction>,
}
@@warning("+30")

@genType
type place = {
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // null means the tap is not in use, undefined would remove the key
  taps: Js.Dict.t<Js.null<Firebase.documentReference<keg>>>,
  users: Js.Dict.t<int>,
}

// use tuple to reduce byte size (hello gRPC) this is converted to records on
// the client through converter
type personsAllItem = (personName, Firebase.Timestamp.t, int, Js.null<string>, option<tapName>)

@genType
type personsIndex = {
  // the key is the person's UUID
  all: Js.Dict.t<personsAllItem>,
}

@genType
type shareLink = {
  createdAt: Firebase.Timestamp.t,
  person: string,
  place: string,
  role: int,
}

type webAuthnUser = {
  lastPresent: Firebase.Timestamp.t,
  lastVerified: Firebase.Timestamp.t,
}
