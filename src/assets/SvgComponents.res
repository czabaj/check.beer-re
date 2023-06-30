module BeerGlassLarge = {
  @module("./beerGlassLarge.svg") @react.component
  external make: (~role: string=?, ~className: string=?) => React.element = "ReactComponent"
}

module BeerGlassSmall = {
  @module("./beerGlassSmall.svg") @react.component
  external make: (~role: string=?, ~className: string=?) => React.element = "ReactComponent"
}
