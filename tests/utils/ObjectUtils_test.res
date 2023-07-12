open Vitest

test("omitUndefined removes all undefined values from an array", t => {
  t->assertions(1)
  let target = {
    "a": 1,
    "b": undefined,
    "c": Null.null,
  }
  let actual = target->ObjectUtils.omitUndefined
  expect(actual)->Expect.toEqual({"a": 1, "c": Null.null})
})
