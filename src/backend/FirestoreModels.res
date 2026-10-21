type personName = string
type personUID = string
type tapName = string

type financialTransaction = {
  amount: int,
  createdAt: Firebase.Timestamp.t,
  keg: Null.t<int>,
  note: Null.t<string>,
  person: Null.t<string>,
}

@@warning("-30")
type rec consumption = {
  milliliters: int,
  person: Firebase.documentReference<person>,
}
@genType
and keg = {
  beer: string,
  consumptions: dict<consumption>,
  createdAt: Firebase.Timestamp.t,
  depletedAt: Null.t<Firebase.Timestamp.t>,
  donors: dict<int>,
  milliliters: int,
  price: int,
  recentConsumptionAt: Null.t<Firebase.Timestamp.t>,
  serial: int,
}
@genType
and person = {
  createdAt: Firebase.Timestamp.t,
  transactions: array<financialTransaction>,
}
@@warning("+30")

type consumptionSymbols = {"300": string, "500": string}

// (role, notificationsSubsription)
type accountTuple = (int, int)

@genType
type place = {
  // key is UUID of the firebase user, value is tuple of various data
  accounts: dict<accountTuple>,
  // maps consumption volume to symbol
  consumptionSymbols: Nullable.t<consumptionSymbols>,
  createdAt: Firebase.Timestamp.t,
  currency: string,
  name: string,
  // null means the tap is not in use, undefined would remove the key
  taps: dict<Null.t<Firebase.documentReference<keg>>>,
}

// use tuple to reduce byte size (hello gRPC) this is converted to records on
// the client through converter
type personsAllItem = (personName, Firebase.Timestamp.t, int, Null.t<string>, option<tapName>)

@genType
type personsIndex = {
  // the key is the person's UUID
  all: dict<personsAllItem>,
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
