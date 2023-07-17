open Dom.Storage2

let keyRememeberedEmail = "email"
let keyPendingEmail = "email_pending"

let getPendingEmail = () => localStorage->getItem(keyPendingEmail)
let setPendingEmail = email => localStorage->setItem(keyPendingEmail, email)
let removePendingEmail = () => localStorage->removeItem(keyPendingEmail)

let getRememberEmail = () => localStorage->getItem(keyRememeberedEmail)
let setRememberEmail = email => localStorage->setItem(keyRememeberedEmail, email)
