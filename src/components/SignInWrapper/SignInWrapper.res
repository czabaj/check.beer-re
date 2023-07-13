@react.component
let make = (~children) => {
  let {data: signInData} = Reactfire.useSigninCheck()

  switch signInData {
  | None => React.null
  | Some({signedIn}) =>
    switch signedIn {
    | true => children
    | false => <Unathenticated />
    }
  }
}
