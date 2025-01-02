type usePromiseResult<'data, 'error> = {
  state: [#idle | #pending | #fulfilled | #rejected],
  data: option<'data>,
  error: option<'error>,
}

let usePromise = (fn: unit => promise<'data>) => {
  let (result, setResult) = React.useState(() => {state: #idle, data: None, error: None})
  let run = () => {
    setResult(prevResult => {...prevResult, state: #pending, error: None})
    fn()
    ->Promise.then(data => {
      setResult(_ => {state: #fulfilled, data: Some(data), error: None})
      Promise.resolve()
    })
    ->Promise.catch(error => {
      setResult(_ => {state: #rejected, data: None, error: Some(error)})
      Promise.resolve()
    })
    ->ignore
  }
  (result, run)
}

type overflowingState<'a> = {
  currentLayoutIndex: int,
  layouts: array<'a>,
  // thresholds is used as a mutable array, never coppied
  thresholds: array<int>,
}

type overfowingAction = Resized({availableWidth: int, contentWidth: int})

let overflowingReducer: (overflowingState<'a>, overfowingAction) => overflowingState<'a> = (
  state,
  action,
) => {
  let newState = ref(state)
  switch action {
  | Resized({availableWidth, contentWidth}) => {
      let {currentLayoutIndex, thresholds} = state
      let overflowing = contentWidth > availableWidth
      if !overflowing {
        let canGrow = currentLayoutIndex !== 0
        if canGrow {
          let widerLayoutThreshold = thresholds->Array.getUnsafe(currentLayoutIndex - 1)
          if availableWidth > widerLayoutThreshold {
            newState := {
                ...state,
                currentLayoutIndex: state.currentLayoutIndex - 1,
              }
          }
        }
      } else {
        // update the threshold if the content width is different
        let currentLayoutThreshold = thresholds->Array.getUnsafe(currentLayoutIndex)
        if contentWidth !== currentLayoutThreshold {
          thresholds->Array.splice(~start=currentLayoutIndex, ~remove=1, ~insert=[contentWidth])
          if %raw(`import.meta.env.DEV`) && currentLayoutIndex !== 0 {
            let widerLayoutThreshold = thresholds->Array.getUnsafe(currentLayoutIndex - 1)
            if contentWidth > widerLayoutThreshold {
              LogUtils.captureException(
                TypeUtils.any(
                  `The threshold for layout "${state.layouts->Array.getUnsafe(
                      currentLayoutIndex,
                    )}" (${contentWidth->Int.toString}px) is wider than threshold for layout "${state.layouts->Array.getUnsafe(
                      currentLayoutIndex - 1,
                    )}" (${widerLayoutThreshold->Int.toString}px)
                    
The layouts should be sorted from widest to narrowest (e.g. ["XL", "MD", "SM"]). This likely means an error in the rendering logic.`,
                ),
              )
            }
          }
        }
        let canShrink = currentLayoutIndex !== state.layouts->Array.length - 1
        if canShrink {
          newState := {
              ...state,
              currentLayoutIndex: currentLayoutIndex + 1,
            }
        }
      }
    }
  }
  newState.contents
}

/**
  * This hooks accepts an array of strings like `["XL", "MD", "SM"]` which must be sorted from widest to narrowest.
  * It returns the first item from the layuouts as long as the content does not overflow the parent, when it overflows,
  * it returns the next layout and it expects that the content will be adapted for narrower screen. It continues in
  * measurement and returns narrower layout as long as there are any available. It remembers the screen threshold where
  * it switched and if the screen grows larger again, it switches back to the wider layout.
  *
  * @example
  *
  * let layout = useIsHorizontallyOverflowing(Some(element), [#xl, #md, #sm])
 */
let useIsHorizontallyOverflowing = (element: Nullable.t<Element.t>, layouts: array<'a>) => {
  let (overflowState, sendOverflowing) = React.useReducer(
    overflowingReducer,
    {
      currentLayoutIndex: 0,
      layouts,
      thresholds: [],
    },
  )
  React.useEffect1(() => {
    switch element {
    | Nullable.Value(el) =>
      let testOverflowing = _ => {
        let availableWidth = el->Element.clientWidth
        let contentWidth = el->Element.scrollWidth
        Js.log({"availableWidth": availableWidth, "contentWidth": contentWidth})
        sendOverflowing(Resized({availableWidth, contentWidth}))
      }
      testOverflowing()
      let resizeObserver = Webapi.ResizeObserver.make(testOverflowing)
      resizeObserver->Webapi.ResizeObserver.observe(el)
      Some(
        () => {
          resizeObserver->Webapi.ResizeObserver.disconnect
        },
      )
    | _ => None
    }
  }, [element])
  layouts->Array.getUnsafe(overflowState.currentLayoutIndex)
}
