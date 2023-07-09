%%raw(`import './styles/index.css'`)

@react.component
let make = () => {
  let url = RescriptReactRouter.useUrl()

  switch url.path {
  | list{} => <Homepage />
  | list{"misto"}
  | list{"misto", ..._} =>
    <React.Suspense fallback={React.string("Loading ...")}>
      <FirebaseProvider>
        <SignInWrapper>
          {switch List.tail(url.path) {
          | Some(list{}) => <MyPlaces />
          | Some(list{"pridat"}) => <AddPlace />
          | Some(list{placeId}) => <Place placeId />
          | Some(list{placeId, "nastaveni"}) => <PlaceSetting placeId />
          | Some(list{placeId, "nastaveni", "osob"}) => <PlacePersonsSetting placeId />
          | _ => <PageNotFound />
          }}
        </SignInWrapper>
      </FirebaseProvider>
    </React.Suspense>
  | _ => <PageNotFound />
  }
}
