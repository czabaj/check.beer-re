type paginatedState = {
  continueWith: option<Db.kegConverted>,
  data: option<array<Db.kegConverted>>,
  error: option<exn>,
  pending: bool,
}
let initialState = {continueWith: None, data: None, error: None, pending: false}

type paginatedAction =
  | FetchMore
  | FetchMoreSuccess(array<Db.kegConverted>)
  | InitialLoad
  | InitialLoadSuccess(array<Db.kegConverted>)
  | LoadingError(exn)

let getConstraints = (limit, startAfter) => {
  let basicConstraints = [
    Firebase.where("depletedAt", #"!=", null),
    Firebase.orderBy("depletedAt", ~direction=#desc),
    // fetching limit+1 to know if there are more kegs to fetch, the extra keg is
    // not displayed, until the user clicks on "fetch more"
    Firebase.limit(limit + 1),
  ]
  switch startAfter {
  | None => basicConstraints
  | Some(keg) => basicConstraints->Array.concat([Firebase.startAfter(keg)])
  }
}

let kegQuerySnapshotToKegs = (kegsSnapshot: Firebase.querySnapshot<Db.kegConverted>) =>
  kegsSnapshot.docs->Array.map(Rxfire.Firestore.snapToData)

let use = (~limit=20, placeId) => {
  let firestore = Firebase.useFirestore()
  let kegsCollectionRef = Db.placeKegsCollectionConverted(firestore, placeId)
  let (paginatedDataState, paginatedDataSend) = ReactUpdate.useReducer(initialState, (
    action,
    state,
  ) => {
    switch (action, state) {
    | (FetchMore, {data: Some(_), continueWith: Some(lastKeg), pending: false}) =>
      ReactUpdate.UpdateWithSideEffects(
        {
          ...state,
          pending: true,
        },
        ({send}) => {
          let constraints = getConstraints(limit, Some(lastKeg))
          Firebase.getDocs(Firebase.query(kegsCollectionRef, constraints))
          ->Promise.then(kegsSnapshot => {
            let data = kegQuerySnapshotToKegs(kegsSnapshot)
            send(FetchMoreSuccess(data))
            Promise.resolve()
          })
          ->Promise.catch(error => {
            send(LoadingError(error))
            Promise.resolve()
          })
          ->ignore
          None
        },
      )
    | (FetchMoreSuccess(newData), {data: Some(previousData)}) =>
      ReactUpdate.Update({
        continueWith: newData->Array.get(limit),
        // TODO: use set of kegs or union funtion for arrays
        data: Some(previousData->Array.concat(newData)),
        error: None,
        pending: false,
      })
    | (InitialLoad, {data: None, continueWith: None, pending: false}) =>
      ReactUpdate.UpdateWithSideEffects(
        {
          ...state,
          pending: true,
        },
        ({send}) => {
          let constraints = getConstraints(limit, None)
          Firebase.getDocs(Firebase.query(kegsCollectionRef, constraints))
          ->Promise.then(kegsSnapshot => {
            let data = kegQuerySnapshotToKegs(kegsSnapshot)
            send(InitialLoadSuccess(data))
            Promise.resolve()
          })
          ->Promise.catch(error => {
            send(LoadingError(error))
            Promise.resolve()
          })
          ->ignore
          None
        },
      )
    | (InitialLoad, {data: None, pending: true}) =>
      // multiple initial loads caused by React@18 concurrent mode in dev
      ReactUpdate.NoUpdate
    | (InitialLoad, {data: Some(_), pending: false}) =>
      // initial load caused by react-hot-reload
      ReactUpdate.NoUpdate
    | (InitialLoadSuccess(data), _) =>
      ReactUpdate.Update({
        continueWith: data->Array.get(limit),
        data: Some(data),
        error: None,
        pending: false,
      })
    | (LoadingError(error), _) =>
      ReactUpdate.Update({
        ...state,
        error: Some(error),
        pending: false,
      })
    | _ => {
        Js.log2("unhandled state and action", {"state": state, "action": action})
        ReactUpdate.NoUpdate
      }
    }
  })
  React.useEffect0(() => {
    paginatedDataSend(InitialLoad)
    None
  })
  switch paginatedDataState {
  | {data: Some(data), continueWith: None} => (Some(data), None)
  | {data: Some(data), continueWith: Some(_)} => (
      Some(data->Array.slice(~start=0, ~end=-1)),
      Some(() => paginatedDataSend(FetchMore)),
    )
  | _ => (None, None)
  }
}
