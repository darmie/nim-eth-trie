import
  rlp/types as rlpTypes

proc toBytesRange*(str: string): BytesRange =
  var s = newSeq[byte](str.len)
  if str.len > 0:
    copyMem(s[0].addr, str[0].unsafeAddr, str.len)
  result = toRange(s)

proc br*(str: string): BytesRange {.inline.} =
  toBytesRange(str)

proc parseBin*(str: string): Bytes =
  result = newSeq[byte](str.len)
  for i in 0..<str.len:
    result[i] = byte(str[i].ord - '0'.ord)

proc b*(str: string): Bytes =
  result = newSeq[byte](str.len)
  for i in 0..<str.len:
    result[i] = byte(str[i])
