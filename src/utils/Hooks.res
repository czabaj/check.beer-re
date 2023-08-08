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