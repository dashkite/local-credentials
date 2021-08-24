import { openDB } from "idb"
import * as Meta from "@dashkite/joy/metaclass"

DB =
  upgrade: (db) ->
    db.createObjectStore "profiles", keyPath: [ "host", "address" ]

Store = run: (handler) -> handler await @db

Meta.mixin Store, [
  Meta.getter "db", -> @_db ?= openDB "zinc", 1, DB
]

export default Store
