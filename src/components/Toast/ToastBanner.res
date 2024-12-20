type classesType = {buttonClose: string, toastBanner: string}

@module("./ToastBanner.module.css") external classes: classesType = "default"

let buttonCloseText = "Zavřít"
let closeButtonPlaceholder = React.string(String.repeat("\xA0", String.length(buttonCloseText) * 2))

@react.component
let make = React.memo(() => {
  let toastTree = Tilia.use(Toast.tree)
  switch toastTree.toasts {
  | [] => React.null
  | messages =>
    <div className=classes.toastBanner>
      {messages
      ->Array.map(message => {
        let (variant, role) = switch message {
        | Error(_) => (`error`, `alert`)
        | Info(_) => (`info`, `status`)
        | Success(_) => (`success`, `status`)
        }
        switch message {
        | Error({id, message, _}) | Info({id, message, _}) | Success({id, message, _}) =>
          React.cloneElement(
            <div key={id} role>
              <div>
                {message}
                {closeButtonPlaceholder}
                <button
                  className={`${Styles.link.base} ${classes.buttonClose}`}
                  onClick={_ => Toast.removeMessage(id)}
                  type_="button">
                  {React.string(buttonCloseText)}
                </button>
              </div>
            </div>,
            {"data-variant": variant},
          )
        }
      })
      ->React.array}
    </div>
  }
})
