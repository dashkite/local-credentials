import {properties} from "panda-parchment"
import {Capability, Confidential} from "./helpers"
import Grants from "./grants"
import Store from "./store"

{EncryptionKeyPair, SignatureKeyPair, SharedKey, PublicKey,
  Message, Envelope, encrypt, decrypt} = Confidential

{Directory, lookup, exercise} = Capability

class Profile

  properties @,
    all:
      get: -> Store.run (db) -> db.getAll "profiles"
    current:
      get: -> Profile.load localStorage.getItem "current"
      set: (profile) -> localStorage.setItem "current", profile.address

  properties @::,
    address: get: -> @keyPairs.encryption.publicKey.to "base64"

  constructor: ({@data = {}, @keyPairs, @grants}) ->

  toObject: ->
    address: @address
    data: @data
    grants: @grants.toObject()
    keyPairs:
      encryption: @keyPairs.encryption.to "base64"
      signature: @keyPairs.signature.to "base64"

  toJSON: -> JSON.stringify @toObject()

  store: -> Store.run (db) => db.put "profiles", @toObject()

  update: (handler) ->
    await handler.call @
    @store()

  delete: -> Store.run (db) => db.delete "profiles", @address

  receive: (publicKey, ciphertext) ->
    sharedKey = SharedKey.create (PublicKey.from "base64", publicKey),
      @keyPairs.encryption.privateKey
    directory = Directory.from "bytes",
      (decrypt sharedKey, Envelope.from "base64", ciphertext).to "bytes"
    @grants.add directory
    @store()

  exercise: ({path, parameters, method}) ->
    {directory} = @grants
    if (bundle = lookup directory, path, parameters)?
      if (_capability = bundle[method.toUpperCase()])?
        {grant, useKeyPairs} = _capability
        claim = exercise @keyPairs.signature,
          useKeyPairs, grant, url: parameters
        claim.to "base64"

  @create: (data) ->
    profile = new Profile
      data: data
      grants: Grants.create()
      keyPairs:
        encryption: await EncryptionKeyPair.create()
        signature: await SignatureKeyPair.create()
    await profile.store()
    profile

  @fromObject: (object) ->
    {data, keyPairs, grants} = object
    new Profile
      data: data
      grants: Grants.fromObject grants
      keyPairs:
        encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
        signature: SignatureKeyPair.from "base64", keyPairs.signature

  @fromJSON: (json) -> @fromObject JSON.parse json

  @toObject: (profile) -> profile.toObject()

  @toJSON: (profile) -> profile.toJSON()

  @load: (address) ->
    Store.run (db) ->
      profile = await db.get "profiles", address
      Profile.fromObject profile if profile?

  @store: (profile) -> profile.store()

  @update: (profile, handler) -> profile.update handler

  @delete: (profile) -> profile.delete()

  @receive: (profile, publicKey, ciphertext) ->
    profile.add publicKey, ciphertext

  @exercise: (profile, request) -> profile.exercise request

export default Profile
