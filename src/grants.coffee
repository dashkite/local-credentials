import {Capability} from "./helpers"

{Directory} = Capability

class Grants

  constructor: ({@directory}) ->

  toObject: -> @directory.to "base64"

  add: (directory) ->
    for template, methods of directory
      for method, entry of methods
        @directory[template] ?= {}
        @directory[template][method] = entry

  @create: -> new Grants directory: Directory.create()

  @toObject: (grants) -> grants.toObject()

  @fromObject: (directory) ->
    new Grants directory: Directory.from "base64", directory

  @add: (grants, directory) -> grants.add directory

export default Grants
