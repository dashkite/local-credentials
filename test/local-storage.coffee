store = {}

LocalStorage =

  getItem: (key) -> store[key]

  setItem: (key, value) -> store[key] = value

  clear: -> store = {}


global.localStorage = LocalStorage
