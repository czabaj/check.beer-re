let addEventListener: ('a, string, (. 'ev) => unit, unit) => unit = %raw(`
  (target, type, listener) => {
    target.addEventListener(type, listener)
    return () => target.removeEventListener(type, listener)
  }
`)
