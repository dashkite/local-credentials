import {tee} from "panda-garden"
import {properties} from "panda-parchment"
import capability from "panda-capability"
import Confidential from "./confidential"

{SharedKey, PublicKey, Message, Envelope, encrypt, decrypt} = Confidential
{Directory, lookup, exercise} = capability Confidential

class Grants

  constructor: ({@profile, @directory}) ->

  properties @::,
    address: get: -> @profile.keyPairs.encryption.publicKey.to "base64"
    key: get: -> "profile/#{@address}/grants"

  exercise: (request) -> Grants.exercise @, request

  add: (directory) -> Grants.add @, directory

  receive: (key, ciphertext) -> Grants.receive @, key, ciphertext

  @create: -> new Grants directory: Directory.create()

  @toObject: ({directory}) -> directory.to "base64"

  @fromObject: (directory) ->
    new Grants directory: Directory.from "base64", directory

  @load: (key) -> Grants.fromObject JSON.parse localStorage.getItem key

  @store: tee (grants) ->
    localStorage.setItem grants.key,
      JSON.stringify Grants.toObject grants

  @add: tee (grants, directory) ->
    if grants.directory?
      for template, methods of directory
        for method, entry of methods
          grants.directory[template] ?= {}
          grants.directory[template][method] = entry
    else
      grants.directory = directory
    Grants.store grants

  @receive: (grants, publicKey, ciphertext) ->
    sharedKey = SharedKey.create (PublicKey.from "base64", publicKey),
      grants.profile.keyPairs.encryption.privateKey
    directory = Directory.from "bytes",
      (decrypt sharedKey, Envelope.from "base64", ciphertext).to "bytes"
    @add grants, directory
    # can't use tee here because we're using this
    grants

  @exercise: ({directory, profile}, {path, parameters, method}) ->
    if (bundle = lookup directory, path, parameters)?
      if (_capability = bundle[method.toUpperCase()])?
        {grant, useKeyPairs} = _capability
        assertion = exercise profile.keyPairs.signature,
          useKeyPairs, grant, url: parameters
        assertion.to "base64"

export default Grants
