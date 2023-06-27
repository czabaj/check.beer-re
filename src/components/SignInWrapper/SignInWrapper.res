@react.component
let make = (~children) => {
  let {data: signInData} = Firebase.useSigninCheck()

  switch signInData {
  | None => React.null
  | Some({signedIn}) =>
    switch signedIn {
    | true => children
    | false => <Unathenticated />
    }
  }
}
