import { openDB } from "idb"

Store = run: (handler) -> handler await @db

Object.defineProperty Store, "db", get: ->
  @_db ?= openDB "zinc", 1,
    upgrade: (db) ->
      await db.createObjectStore "profiles", keyPath: "address"

export default Store
