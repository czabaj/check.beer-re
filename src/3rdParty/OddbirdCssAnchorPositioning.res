type anchorPositioningPolyfillFn = unit => promise<unit>

@module("@oddbird/css-anchor-positioning/fn")
external polyfillAnchorPositioning: anchorPositioningPolyfillFn = "default"

let debouncedPolyfillSource = Rxjs.Subject.make()
let debouncedPolyfillSubscription =
  debouncedPolyfillSource
  ->Rxjs.toObservable
  ->Rxjs.op(Rxjs.debounceTime(100))
  ->Rxjs.subscribeFn(() => {
    polyfillAnchorPositioning()->ignore
  })

let polyfillDebounced = () => {
  debouncedPolyfillSource->Rxjs.Subject.next()
}
