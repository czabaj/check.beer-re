let omitUndefined: {..} => {..} = %raw("data => {
  const result = {}
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined) {
      result[key] = value
    }
  }
  return result
}")

let setIn = (obj: {..}, key: string, value: 'a): {..} => {
  let result = obj->Object.copy
  result->Object.set(key, value)
  result
}

let setInD = (dict: Dict.t<'a>, key: string, value: 'a): Dict.t<'a> => {
  let result = dict->Dict.copy
  result->Dict.set(key, value)
  result
}

@val @scope("window")
external structuredClone: 'a => 'a = "structuredClone"
