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
