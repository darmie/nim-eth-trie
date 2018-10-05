import
  random, sets, unittest, strutils, sets,
  eth_trie/[db, binary, branches]

suite "branches utils":

  proc testTrie(): BinaryTrie =
    var db = newMemoryDB()
    var trie = initBinaryTrie(db)

    trie.set("\x12\x34\x56\x78\x9a", "9a")
    trie.set("\x12\x34\x56\x78\x9b", "9b")
    trie.set("\x12\x34\x56\xff", "ff")
    trie

  const branchExistData = [
    ("\x12\x34", true),
    ("\x12\x34\x56\x78\x9b", true),
    ("\x12\x56", false),
    ("\x12\x34\x56\xff\xff", false),
    ("\x12\x34\x56", true),
    ("\x12\x34\x56\x78", true)
  ]

  test "branch exists":
    var trie = testTrie()
    var db = trie.getDB()
    for c in branchExistData:
      let keyPrefix = c[0].toRange
      let if_exist = c[1]
      check checkIfBranchExist(db, trie.getRootHash(), keyPrefix) == if_exist

  const branchData = [
    ("\x12\x34", true),
    ("\x12\x34\x56\xff", true),
    ("\x12\x34\x56\x78\x9b", true),
    ("\x12\x56", true),
    ("\x12\x34\x56\xff\xff", false),
    ("", false)
  ]

  test "branch":
    var trie = testTrie()
    var db = trie.getDB()
    for c in branchData:
      let key = c[0].toRange
      let keyValid = c[1]

      if keyValid:
        let branch = getBranch(db, trie.getRootHash(), key)
        check isValidBranch(branch, trie.getRootHash(), key, trie.get(key))
      else:
        try:
          discard getBranch(db, trie.getRootHash(), key)
        except InvalidKeyError:
          check(true)
        except:
          check(false)

  const trieNodesData = [
    ("#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xca", @["\x029a"]),
    ("\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
      @["\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x029a",
       "\x029b"]),
    ("\x13\x07<\xa0w6\xd5O\x91\x93\xb1\xde,0}\xe7\xee\x82\xd7\xf6\xce\x1b^\xb7}\"\n\xe4&\xe2\xd7v",
      @["\x00\x82<M\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
       "\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x029a",
       "\x029b"]),
    ("X\x99\x8f\x13\xeb\x9bF\x08\xec|\x8b\xd8}\xca\xed\xda\xbb4\tl\xc8\x9bJ;J\xed\x11\x86\xc2\xd7+\xca",
      @["\x00\x80\x124V\xde\xb5\x8f\xdb\x98\xc0\xe8\xed\x10\xde\x84\x89\xe1\xc3\x90\xbeoi7y$sJ\x07\xa1h\xf5t\x1c\xac\r+",
       "\x01\x13\x07<\xa0w6\xd5O\x91\x93\xb1\xde,0}\xe7\xee\x82\xd7\xf6\xce\x1b^\xb7}\"\n\xe4&\xe2\xd7v7\x94\x07\x18\xc9\x96E\xf1\x9bS1sv\xa2\x8b\x9a\x88\xfd/>5\xcb3\x9e\x03\x08\r\xe2\xe1\xd5\xaaq",
       "\x00\x82<M\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
       "\x00\x83\x7fR\xce\xe1\xe1 +\x96\xde\xae\xcdV\x13\x9a \x90.7H\xb6\x80\t\x10\xe1(\x03\x15\xde\x94\x17X\xee\xe1",
       "\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x02ff",
       "\x029a",
       "\x029b"]),
    ("\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p", @[]),
    (repeat('0', 32), @[])
  ]

  proc toRanges(x: seq[string]): seq[BytesRange] =
    result = newSeq[BytesRange](x.len)
    for i, c in x: result[i] = toRange(c)

  test "get trie nodes":
    var trie = testTrie()
    var db = trie.getDB()
    for c in trieNodesData:
      let root = c[0].toRange()
      let nodes = toRanges(c[1])
      check toSet(nodes) == toSet(getTrieNodes(db, root))

  const witnessData = [
    ("\x12\x34\x56\x78\x9b",
      @["\x00\x80\x124V\xde\xb5\x8f\xdb\x98\xc0\xe8\xed\x10\xde\x84\x89\xe1\xc3\x90\xbeoi7y$sJ\x07\xa1h\xf5t\x1c\xac\r+",
       "\x01\x13\x07<\xa0w6\xd5O\x91\x93\xb1\xde,0}\xe7\xee\x82\xd7\xf6\xce\x1b^\xb7}\"\n\xe4&\xe2\xd7v7\x94\x07\x18\xc9\x96E\xf1\x9bS1sv\xa2\x8b\x9a\x88\xfd/>5\xcb3\x9e\x03\x08\r\xe2\xe1\xd5\xaaq",
       "\x00\x82<M\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
       "\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x029b"]),
    ("\x12\x34\x56\x78",
      @["\x00\x80\x124V\xde\xb5\x8f\xdb\x98\xc0\xe8\xed\x10\xde\x84\x89\xe1\xc3\x90\xbeoi7y$sJ\x07\xa1h\xf5t\x1c\xac\r+",
       "\x01\x13\x07<\xa0w6\xd5O\x91\x93\xb1\xde,0}\xe7\xee\x82\xd7\xf6\xce\x1b^\xb7}\"\n\xe4&\xe2\xd7v7\x94\x07\x18\xc9\x96E\xf1\x9bS1sv\xa2\x8b\x9a\x88\xfd/>5\xcb3\x9e\x03\x08\r\xe2\xe1\xd5\xaaq",
       "\x00\x82<M\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
       "\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x029a",
       "\x029b"]),
    ("\x12\x34\x56",
      @["\x00\x80\x124V\xde\xb5\x8f\xdb\x98\xc0\xe8\xed\x10\xde\x84\x89\xe1\xc3\x90\xbeoi7y$sJ\x07\xa1h\xf5t\x1c\xac\r+",
       "\x01\x13\x07<\xa0w6\xd5O\x91\x93\xb1\xde,0}\xe7\xee\x82\xd7\xf6\xce\x1b^\xb7}\"\n\xe4&\xe2\xd7v7\x94\x07\x18\xc9\x96E\xf1\x9bS1sv\xa2\x8b\x9a\x88\xfd/>5\xcb3\x9e\x03\x08\r\xe2\xe1\xd5\xaaq",
       "\x00\x82<M\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
       "\x00\x83\x7fR\xce\xe1\xe1 +\x96\xde\xae\xcdV\x13\x9a \x90.7H\xb6\x80\t\x10\xe1(\x03\x15\xde\x94\x17X\xee\xe1",
       "\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x02ff",
       "\x029a",
       "\x029b"]),
    ("\x12",
      @["\x00\x80\x124V\xde\xb5\x8f\xdb\x98\xc0\xe8\xed\x10\xde\x84\x89\xe1\xc3\x90\xbeoi7y$sJ\x07\xa1h\xf5t\x1c\xac\r+",
       "\x01\x13\x07<\xa0w6\xd5O\x91\x93\xb1\xde,0}\xe7\xee\x82\xd7\xf6\xce\x1b^\xb7}\"\n\xe4&\xe2\xd7v7\x94\x07\x18\xc9\x96E\xf1\x9bS1sv\xa2\x8b\x9a\x88\xfd/>5\xcb3\x9e\x03\x08\r\xe2\xe1\xd5\xaaq",
       "\x00\x82<M\x84\x97\xc1\xf7S\xf5\xa2\xbb>\xbd\xe9\xc3t\x0f\xac/\xad\xa8\x01\xff\x9aE\t\xc1\xab\x9e\xa3|\xc7Z\xb0v",
       "\x00\x83\x7fR\xce\xe1\xe1 +\x96\xde\xae\xcdV\x13\x9a \x90.7H\xb6\x80\t\x10\xe1(\x03\x15\xde\x94\x17X\xee\xe1",
       "\x01#\xf037,w\xb9()\x0e4\x92\xdf\x11\xca\xea\xa5\x13/\x10\x1bJ\xa7\x16\x07\x07G\xb1\x01_\x16\xcaG\xe9\xb6\xa1\xfa\xd5\x82\xf4k\x04\x9c\x8e\xc8\x17\xb4G\xe1c*n\xf4o\x02\x85\xf1\x19\xa8\x83`\xfb\xf8\xa2",
       "\x02ff",
       "\x029a",
       "\x029b"]),
    (repeat('0', 32),
      @["\x00\x80\x124V\xde\xb5\x8f\xdb\x98\xc0\xe8\xed\x10\xde\x84\x89\xe1\xc3\x90\xbeoi7y$sJ\x07\xa1h\xf5t\x1c\xac\r+"]),
  ]

  test "get witness for key prefix":
    var trie = testTrie()
    var db = trie.getDB()
    for c in witnessData:
      let key   = c[0].toRange
      let nodes = toRanges(c[1])

      if nodes.len != 0:
        let x = toSet(nodes)
        let y = toSet(getWitness(db, trie.getRootHash(), key))
        check x == y
