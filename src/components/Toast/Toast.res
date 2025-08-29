@val @scope(("window", "crypto"))
external randomUUID: unit => string = "randomUUID"

type toast =
  | Error({id: string, message: Jsx.element, onClose?: unit => unit})
  | Info({id: string, message: Jsx.element, onClose?: unit => unit})
  | Success({id: string, message: Jsx.element, onClose?: unit => unit})

type state = {mutable toasts: array<toast>}

let tree = Tilia.tilia({
  toasts: [],
})

let addMessage = toast => {
  tree.toasts = [...tree.toasts, toast]
}

let removeMessage = id => {
  tree.toasts =
    tree.toasts->Array.filter(message =>
      switch message {
      | Error({id: id_, _}) | Info({id: id_, _}) | Success({id: id_, _}) => id_ !== id
      }
    )
}
