import {tee} from "panda-garden"
import capability from "panda-capability"
import Confidential from "./confidential"

{SharedKey, PublicKey, Message, Envelope, encrypt, decrypt} = Confidential
{Directory, lookup, exercise} = capability Confidential

class Grants

  constructor: (@directory) ->

  exercise: (request) -> Grants.exercise @, request
  add: (directory) -> Grants.add @, directory

  store: -> Grants.store @

  @store: tee (grants) ->
    if grants.directory?
      @cached = grants
      Local.store "directory", await @encrypt grants.directory

  @load: -> @cached ?= new Grants @decrypt Local.load "directory"

  @decrypt: (text) ->
     try
      encryptedDirectory = Envelope.from "base64", text
      encryptionKey = SharedKey.create Profile.load().keyPairs.encryption
      message = decrypt encryptionKey, encryptedDirectory
      Directory.from "bytes", message.to "bytes"
    catch error
      console.warn "Missing or corrupted grants dictionary."

  @encrypt: (directory) ->
    sharedKey = SharedKey.create Profile.load().keyPairs.encryption
    encryptedDirectory = await encrypt sharedKey,
      Message.from "bytes", directory.to "bytes"
    encryptedDirectory.to "base64"

  @add: tee (grants, directory) ->
    if grants.directory?
      for template, methods of directory
        for method, entry of methods
          grants.directory[template] ?= {}
          grants.directory[template][method] = entry
    else
      grants.directory = directory
    grants.store()

  @recieve: (key, text) ->
    key = SharedKey.create (PublicKey.from "base64", key),
      (Profile.load().keyPairs.encryption.privateKey)
    Directory.from "bytes",
      (decrypt sharedKey, Envelope.from "base64", text).to "bytes"

  @exercise: ({directory}, {path, parameters, method}) ->
    if directory? && (bundle = lookup directory, path, parameters)?
      {grant, useKeyPairs} = bundle[method.toUpperCase()]
      assertion = exercise (Profile.load().keyPairs.signature),
        useKeyPairs, grant, url: parameters
      assertion.to "base64"

export default Grants
