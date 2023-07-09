let omitD: (Js.Dict.t<'a>, array<string>) => Js.Dict.t<'a> = %raw("(data, keys) => {
  const result = {}
  for (const [key, value] of Object.entries(data)) {
    if (!keys.includes(key)) {
      result[key] = value
    }
  }
  return result
}")

let omitUndefined: {..} => {..} = %raw("data => {
  const result = {}
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined) {
      result[key] = value
    }
  }
  return result
}")

let setIn: (option<{..}>, string, 'a) => {..} = %raw("(obj, key, value) => {
  const result = {...obj}
  result[key] = value
  return result
}")

let setInD: (Js.Dict.t<'a>, string, 'a) => Js.Dict.t<'a> = %raw("(...args) => setIn(...args)")
