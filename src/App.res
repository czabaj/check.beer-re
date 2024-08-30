%%raw(`import './styles/index.css'`)
%%raw(`import '@oddbird/popover-polyfill'`)

type anchorPositioningPolyfillFn = unit => promise<unit>

@module("@oddbird/css-anchor-positioning/fn")
external polyfillAnchorPositioning: anchorPositioningPolyfillFn = "default"

polyfillAnchorPositioning()->ignore

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
          {switch List.tail(url.path) {
          | Some(list{}) => <MyPlaces />
          | Some(list{placeId}) => <Place placeId />
          | Some(list{placeId, "nastaveni"}) => <PlaceSetting placeId />
          | Some(list{placeId, "nastaveni", "osob"}) => <PlacePersonsSetting placeId />
          | _ => <PageNotFound />
          }}
        </SignInWrapper>
      </FirebaseAuthProvider>
    | list{"s", linkId} =>
      <FirebaseAuthProvider>
        <SignInWrapper>
          <ShareLinkResolver linkId />
        </SignInWrapper>
      </FirebaseAuthProvider>
    | _ => <PageNotFound />
    }}
  </React.Suspense>
}
