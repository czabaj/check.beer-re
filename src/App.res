%%raw(`import './styles/index.css'`)
%%raw(`import '@oddbird/popover-polyfill'`)
%%raw(`import '@oddbird/popover-polyfill/dist/popover.css'`)

@react.component
let make = () => {
  let url = RescriptReactRouter.useUrl()

  switch url.path {
  | list{} => <Homepage />
  | list{"misto"}
  | list{"misto", ..._} =>
    <React.Suspense fallback={<LoadingFullscreen />}>
      <FirebaseProvider>
        <SignInWrapper>
          {switch List.tail(url.path) {
          | Some(list{}) => <MyPlaces />
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
