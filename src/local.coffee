Local =
  load: (key) -> window.localStorage.getItem key
  store: (key, value) -> window.localStorage.setItem key, value

export default Local
