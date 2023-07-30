%%raw(`import './styles/index.css'`)
%%raw(`import '@oddbird/popover-polyfill'`)
%%raw(`import '@oddbird/popover-polyfill/dist/popover.css'`)

@react.component
let make = () => {
  let url = RescriptReactRouter.useUrl()

  <React.Suspense fallback={<LoadingFullscreen />}>
    {switch url.path {
    | list{} => <Homepage />
    | list{"misto"}
    | list{"misto", ..._} =>
      <FirebaseAuthProvider>
        <SignInWrapper>
          <FirebaseFirestoreProvider>
            {switch List.tail(url.path) {
            | Some(list{}) => <MyPlaces />
            | Some(list{placeId}) => <Place placeId />
            | Some(list{placeId, "nastaveni"}) => <PlaceSetting placeId />
            | Some(list{placeId, "nastaveni", "osob"}) => <PlacePersonsSetting placeId />
            | _ => <PageNotFound />
            }}
          </FirebaseFirestoreProvider>
        </SignInWrapper>
      </FirebaseAuthProvider>
    | list{"s", linkId} =>
      <FirebaseAuthProvider>
        <SignInWrapper>
          <FirebaseFirestoreProvider>
            <ShareLinkResolver linkId />
          </FirebaseFirestoreProvider>
        </SignInWrapper>
      </FirebaseAuthProvider>
    | _ => <PageNotFound />
    }}
  </React.Suspense>
}
