import
  tables, hashes, sets,
  nimcrypto/[hash, keccak], rlp,
  defs, db_tracing

type
  MemDBRec = object
    refCount: int
    value: Bytes

  MemoryLayer* = ref object of RootObj
    records: Table[Bytes, MemDBRec]
    deleted: HashSet[Bytes]

  TrieDatabaseConcept* = concept DB
    mixin put, del, get

    put(var DB, KeccakHash, BytesRange)
    del(var DB, KeccakHash)
    get(DB, KeccakHash) is Bytes
    contains(DB, KeccakHash) is bool

  # XXX: poor's man vtref types
  PutProc = proc (db: RootRef, key, val: openarray[byte])
  GetProc = proc (db: RootRef, key: openarray[byte]): Bytes # Must return empty seq if not found
  DelProc = proc (db: RootRef, key: openarray[byte])
  ContainsProc = proc (db: RootRef, key: openarray[byte]): bool

  TrieDatabaseRef* = ref object
    obj: RootRef
    putProc: PutProc
    getProc: GetProc
    delProc: DelProc
    containsProc: ContainsProc
    mostInnerTransaction: DbTransaction

  DbTransaction* = ref object
    db: TrieDatabaseRef
    parentTransaction: DbTransaction
    modifications: MemoryLayer
    committed: bool

proc put*(db: TrieDatabaseRef, key, val: openarray[byte])
proc get*(db: TrieDatabaseRef, key: openarray[byte]): Bytes
proc del*(db: TrieDatabaseRef, key: openarray[byte])
proc beginTransaction*(db: TrieDatabaseRef): DbTransaction

proc keccak*(r: BytesRange): KeccakHash =
  keccak256.digest r.toOpenArray

proc get*(db: MemoryLayer, key: openarray[byte]): Bytes =
  result = db.records.getOrDefault(@key).value
  traceGet key, result

proc del*(db: MemoryLayer, key: openarray[byte]) =
  traceDel key

  # The database should ensure that the empty key is always active:
  if key != emptyRlpHash.data:
    # TODO: This is quite inefficient and it won't be necessary once
    # https://github.com/nim-lang/Nim/issues/7457 is developed.
    let key = @key

    db.records.withValue(key, v):
      dec v.refCount
      if v.refCount <= 0:
        db.records.del(key)
        db.deleted.incl(key)

proc contains*(db: MemoryLayer, key: openarray[byte]): bool =
  db.records.hasKey(@key)

proc put*(db: MemoryLayer, key, val: openarray[byte]) =
  tracePut key, val

  # TODO: This is quite inefficient and it won't be necessary once
  # https://github.com/nim-lang/Nim/issues/7457 is developed.
  let key = @key

  db.deleted.excl(key)

  if key.len != 32:
    # This is not a Trie key, but a regular system mutable key
    # (e.g. the cannonical head hash). We don't need to ref count such keys.
    db.records[key] = MemDBRec(refCount: 1, value: @val)
  else:
    db.records.withValue(key, v) do:
      inc v.refCount
      if v.value != val: v.value = @val
    do:
      db.records[key] = MemDBRec(refCount: 1, value: @val)

proc newMemoryLayer: MemoryLayer =
  result.new
  result.records = initTable[Bytes, MemDBRec]()
  result.deleted = initSet[Bytes]()

proc commit(memDb: MemoryLayer, db: TrieDatabaseRef) =
  for k in memDb.deleted:
    db.del(k)

  for k, v in memDb.records:
    db.put(k, v.value)

proc init(db: var MemoryLayer) =
  db = newMemoryLayer()

proc newMemoryDB*: TrieDatabaseRef =
  new result
  discard result.beginTransaction
  put(result, emptyRlpHash.data, emptyRlp)

proc totalRecordsInMemoryDB*(db: TrieDatabaseRef): int =
  # Make sure this is really a MemoryDB
  assert db.obj == nil and
         db.mostInnerTransaction != nil and
         db.mostInnerTransaction.parentTransaction == nil

  return db.mostInnerTransaction.modifications.records.len

proc beginTransaction*(db: TrieDatabaseRef): DbTransaction =
  new result
  result.db = db
  init result.modifications

  result.parentTransaction = db.mostInnerTransaction
  db.mostInnerTransaction = result

proc rollback*(t: DbTransaction) =
  # Transactions should be handled in a strictly nested fashion.
  # Any child transaction must be committed or rolled-back before
  # its parent transactions:
  doAssert t.db.mostInnerTransaction == t and not t.committed
  t.db.mostInnerTransaction = t.parentTransaction

proc commit*(t: DbTransaction) =
  # Transactions should be handled in a strictly nested fashion.
  # Any child transaction must be committed or rolled-back before
  # its parent transactions:
  doAssert t.db.mostInnerTransaction == t and not t.committed
  t.db.mostInnerTransaction = t.parentTransaction
  t.modifications.commit(t.db)
  t.committed = true

proc dispose*(t: DbTransaction) {.inline.} =
  if not t.committed:
    t.rollback()

proc safeDispose*(t: DbTransaction) {.inline.} =
  if t != nil and not t.committed:
    t.rollback()

proc putImpl[T](db: RootRef, key, val: openarray[byte]) =
  mixin put
  put(T(db), key, val)

proc getImpl[T](db: RootRef, key: openarray[byte]): Bytes =
  mixin get
  return get(T(db), key)

proc delImpl[T](db: RootRef, key: openarray[byte]) =
  mixin del
  del(T(db), key)

proc containsImpl[T](db: RootRef, key: openarray[byte]): bool =
  mixin contains
  return contains(T(db), key)

proc trieDB*[T: RootRef](x: T): TrieDatabaseRef =
  mixin del, get, put

  new result
  result.obj = x
  result.putProc = putImpl[T]
  result.getProc = getImpl[T]
  result.delProc = delImpl[T]
  result.containsProc = containsImpl[T]

proc put*(db: TrieDatabaseRef, key, val: openarray[byte]) =
  var t = db.mostInnerTransaction
  if t != nil:
    t.modifications.put(key, val)
  else:
    db.putProc(db.obj, key, val)

proc get*(db: TrieDatabaseRef, key: openarray[byte]): Bytes =
  # TODO: This is quite inefficient and it won't be necessary once
  # https://github.com/nim-lang/Nim/issues/7457 is developed.
  let key = @key

  var t = db.mostInnerTransaction
  while t != nil:
    result = t.modifications.records.getOrDefault(key).value
    if result.len > 0 or key in t.modifications.deleted:
      return
    t = t.parentTransaction

  if db.getProc != nil:
    result = db.getProc(db.obj, key)

proc del*(db: TrieDatabaseRef, key: openarray[byte]) =
  var t = db.mostInnerTransaction
  if t != nil:
    t.modifications.del(key)
  else:
    db.delProc(db.obj, key)

proc contains*(db: TrieDatabaseRef, key: openarray[byte]): bool =
  # TODO: This is quite inefficient and it won't be necessary once
  # https://github.com/nim-lang/Nim/issues/7457 is developed.
  let key = @key

  var t = db.mostInnerTransaction
  while t != nil:
    result = key in t.modifications.records
    if result or key in t.modifications.deleted:
      return
    t = t.parentTransaction

  if db.containsProc != nil:
    result = db.containsProc(db.obj, key)

