type classesType = {root: string}

@module("./Homepage.module.css") external classes: classesType = "default"

let supportsTransitionApi: bool = %raw(`typeof document.startViewTransition === 'function'`)

@module("react-dom")
external flushSync: (unit => unit) => unit = "flushSync"
@val @scope("document")
external startViewTransition: (unit => unit) => unit = "startViewTransition"

@gentype @react.component
let make = () => {
  <div className=classes.root>
    <div className=Styles.page.centered>
      <header>
        <h1 ariaLabel="Check Beerk" className="text-center" />
        <p> {React.string("Pivní zápisník")} </p>
      </header>
      <main>
        <a
          className={Styles.button.sizeLarge}
          href="/misto"
          onClick={RouterUtils.handleLinkClick((. ()) => {
            let navigate = () => RescriptReactRouter.push("/misto")
            if !supportsTransitionApi {
              navigate()
            } else {
              startViewTransition(_ => {
                flushSync(navigate)
              })
            }
          })}>
          {React.string("Otevřít")}
        </a>
      </main>
    </div>
  </div>
}
