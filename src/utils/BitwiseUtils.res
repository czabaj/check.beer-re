let bitAnd = (a: int, b: int): int => %raw(`a & b`)

let bitOr = (a: int, b: int): int => %raw(`a | b`)

let bitNot = (a: int): int => %raw(`~a`)
