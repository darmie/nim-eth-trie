import
  ethereum_trie/utils/binaries, test_utils,
  rlp/types as rlpTypes, random, unittest

func generateBytes(len: int): BytesRange =
  var res = newRange[byte](len)
  for i in 0..<len:
    res[i] = byte(i mod 0xFF)
  result = res

proc generateRandomZeroOne(len: int): Bytes =
  random.randomize()
  result = newSeq[byte](len)
  for i in 0..<len:
    result[i] = byte(random.rand(1))

test "basic_test":
  let binbin = parseBin("0100000101010011010000110100100101001001")
  check(encodeToBin(br("ASCII")) == binbin)

  let asc = decodeFromBin(binbin)
  check(asc == b("ASCII"))

test "test_full_8bit":
  for i in 0..<1024:
    let ori = generateBytes(i)
    let bin = ori.encodeToBin()
    let res = bin.decodeFromBin().toRange
    check(ori == res)

#test "test_keypath_encoding":
#    let i = 1023
#    var value = generateRandomZeroOne(i)
#    echo value.len
#    var bk = encodeFromBinKeypath(value.toRange)
#    var res = decodeToBinKeypath(bk.toRange)
#    check(res.len == value.len)
#    #check(res == value)
