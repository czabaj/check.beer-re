LogUtils.initSentry()

let updateSWRef = ref(ignore)
updateSWRef :=
  ServiceWorker.registerSW({
    onNeedRefresh: () => {
      Toast.addMessage(
        Info({
          id: "sw-need-refresh",
          message: <>
            {React.string("Je k dispozici nová verze\xA0\xA0")}
            <button
              className={`${Styles.link.base}`}
              onClick={_ => updateSWRef.contents()}
              type_="button">
              {React.string("Aktualizovat")}
            </button>
          </>,
        }),
      )
    },
    onOfflineReady: () => {
      if !AppStorage.hasSeenOfflineModeReady() {
        Toast.addMessage(
          Info({
            id: "sw-offline-ready",
            message: React.string("Po přihlášení se stránka obejde i bez internetu."),
            onClose: () => {
              AppStorage.markSeenOfflineModeReady()
            },
          }),
        )
      }
    },
  })

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
