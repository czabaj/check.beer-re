module Auth = {
  @module("rxfire/auth")
  external user: Firebase.Auth.t => Rxjs.t<
    Rxjs.foreign,
    Rxjs.void,
    Js.Nullable.t<Firebase.User.t>,
  > = "user"
}

module Firestore = {
  @module("rxfire/firestore")
  external collection: Firebase.query<'a> => Rxjs.t<
    Rxjs.foreign,
    Rxjs.void,
    array<Firebase.querySnapshot<'a>>,
  > = "collection"

  type dataOptions = {idField?: string}

  @module("rxfire/firestore")
  external collectionData: (
    Firebase.query<'a>,
    @as(json`{ "idField": "uid" }`) _,
  ) => Rxjs.t<Rxjs.foreign, Rxjs.void, array<'a>> = "collectionData"

  @module("rxfire/firestore")
  external doc: Firebase.documentReference<'a> => Rxjs.t<
    Rxjs.foreign,
    Rxjs.void,
    Firebase.documentSnapshot<'a>,
  > = "doc"

  @module("rxfire/firestore")
  external snapToData: (Firebase.documentSnapshot<'a>, @as(json`{ "idField": "uid" }`) _) => 'a =
    "snapToData"

  @module("rxfire/firestore") @val
  external docData: (
    Firebase.documentReference<'a>,
    @as(json`{ "idField": "uid" }`) _,
  ) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'a> = "docData"
}
