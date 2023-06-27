@val @scope("Object")
external clone: (@as(json`{}`) _, Js.Dict.t<'a>) => Js.Dict.t<'a> = "assign"
