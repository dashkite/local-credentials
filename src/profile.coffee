import {properties, toUpper} from "panda-parchment"
import Events from "@dashkite/events"
import {Capability, Confidential} from "./helpers"
import Grants from "./grants"
import Store from "./store"

{EncryptionKeyPair, SignatureKeyPair, SharedKey, PublicKey,
  Message, Envelope, encrypt, decrypt} = Confidential

{Directory, lookup, exercise} = Capability

class Profile

  @Confidential = Confidential

  properties @,
    all:
      get: -> Store.run (db) -> db.getAll "profiles"
    current:
      get: ->
        if (json = localStorage.getItem "current")?
          {host, address} = JSON.parse json
          Profile.load host, address
      set: (profile) ->
        {host, address} = profile
        localStorage.setItem "current", JSON.stringify {host, address}
    events:
      get: -> @_events ?= Events.create()

  properties @::,
    address: get: -> @keyPairs.encryption.publicKey.to "base64"
    publicKeys: get: ->
      encryption: @keyPairs.encryption.publicKey.to "base64"
      signature: @keyPairs.signature.publicKey.to "base64"

  constructor: ({@host, @data = {}, @keyPairs, @grants}) ->

  toObject: ->
    host: @host
    address: @address
    data: @data
    grants: @grants.toObject()
    keyPairs:
      encryption: @keyPairs.encryption.to "base64"
      signature: @keyPairs.signature.to "base64"

  toJSON: -> JSON.stringify @toObject()

  store: ->
    await Store.run (db) => db.put "profiles", @toObject()
    Profile.dispatch "update", @

  update: (handler) ->
    await handler.call @
    @store()

  delete: -> Store.run (db) => db.delete "profiles", [ @host, @address ]

  receive: (publicKey, ciphertext) ->
    sharedKey = SharedKey.create (PublicKey.from "base64", publicKey),
      @keyPairs.encryption.privateKey
    directory = Directory.from "bytes",
      (decrypt sharedKey, Envelope.from "base64", ciphertext).to "bytes"
    @grants.add directory
    @store()


  lookup: do ({directory, methods, contract, claim} = {}) ->
    ({path, parameters, method}) ->
      {directory} = @grants
      if (methods = lookup directory, path, parameters)?
        methods[(toUpper method)]

  exercise: do ({directory, methods, contract, claim} = {}) ->
    ({path, parameters, method}) ->
      {directory} = @grants
      if (methods = lookup directory, path, parameters)?
        method = toUpper method
        if (contract = methods[(toUpper method)])?
          claim = exercise @keyPairs.signature, contract,
            template: parameters
            method: method
            claimant:
              # TODO make determination (web v literal) dynamic
              #      we can inspect the contract to do this per David
              literal: @keyPairs.signature.publicKey.to "base64"
          claim.to "base64"

  @create: (host, data) ->
    profile = new Profile
      host: host
      data: data
      grants: Grants.create()
      keyPairs:
        encryption: await EncryptionKeyPair.create()
        signature: await SignatureKeyPair.create()
    await profile.store()
    profile

  @fromObject: (object) ->
    {host, data, keyPairs, grants} = object
    new Profile
      host: host
      data: data
      grants: Grants.fromObject grants
      keyPairs:
        encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
        signature: SignatureKeyPair.from "base64", keyPairs.signature

  @fromJSON: (json) -> @fromObject JSON.parse json

  @toObject: (profile) -> profile.toObject()

  @toJSON: (profile) -> profile.toJSON()

  @load: (host, address) ->
    Store.run (db) ->
      profile = await db.get "profiles", [ host, address ]
      Profile.fromObject profile if profile?

  @store: (profile) -> profile.store()

  @update: (profile, handler) -> profile.update handler

  @delete: (profile) -> profile.delete()

  @dispatch: (name, value) -> @events.dispatch name, value

  @on: (description) -> @events.on description

  @receive: (profile, publicKey, ciphertext) ->
    profile.add publicKey, ciphertext

  @lookup: (profile, request) -> profile.lookup request

  @exercise: (profile, request) -> profile.exercise request


export default Profile
