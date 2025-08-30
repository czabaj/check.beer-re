type emptyProps = {}

module NeverResolvingLazyComponent = {
  let make = React.lazy_(() => Promise.make((_: React.component<emptyProps> => unit, _) => ()))
}

@react.component
let make = (~to) => {
  RescriptReactRouter.replace(to)
  <NeverResolvingLazyComponent />
}
