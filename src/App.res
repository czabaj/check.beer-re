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
          {
            let maybePlaceSubPath = List.tail(url.path)
            switch maybePlaceSubPath {
            | None
            | Some(list{}) =>
              <MyPlaces />
            | Some(placeSubPath) => {
                let placeId = List.headExn(placeSubPath)
                let placeIdSub = List.tail(placeSubPath)
                <>
                  <React.Suspense fallback={React.null}>
                    <FcmTokenSync placeId />
                  </React.Suspense>
                  {switch placeIdSub {
                  | Some(list{}) => <Place placeId />
                  | Some(list{"nastaveni"}) => <PlaceSetting placeId />
                  | Some(list{"nastaveni", "osob"}) => <PlacePersonsSetting placeId />
                  | _ => <PageNotFound />
                  }}
                </>
              }
            }
          }
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
    <ToastBanner />
  </React.Suspense>
}
