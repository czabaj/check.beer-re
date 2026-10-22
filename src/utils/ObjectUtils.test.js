import { describe, expect, it } from "vitest";

import { omitUndefined } from "./ObjectUtils.bs.jsx";

describe("ObjectUtils", () => {
  it("omitUndefined removes all undefined values from an object", () => {
    const actual = omitUndefined({ a: 1, b: undefined, c: null });
    expect(actual).toEqual({ a: 1, c: null });
    expect("b" in actual).toBe(false);
  });
});
