%%raw(`
Sentry.init({
  environment: import.meta.env.MODE,
  dsn: "https://85aeb6b971b04c4cb49af3a52f2ad81e@o4505561027903488.ingest.sentry.io/4505561029607424",
});
`)

open Reactfire

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
