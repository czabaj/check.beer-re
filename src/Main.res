

open Firebase

ReactDOM.querySelector("#root")
->Option.getExn
->ReactDOM.Client.createRoot
->ReactDOM.Client.Root.render(
  <React.StrictMode>
    <FirebaseAppProvider firebaseConfig suspense={true}>
      <ReactIntl.IntlProvider
        locale="cs"
        onError={err => {
          %raw(`process.env.NODE_ENV === 'development' && err.code !== "MISSING_TRANSLATION" && console.error(err)`)
        }}>
        <App />
      </ReactIntl.IntlProvider>
    </FirebaseAppProvider>
  </React.StrictMode>,
)
