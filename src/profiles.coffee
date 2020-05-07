import {properties} from "panda-parchment"
import {tee} from "panda-garden"
import Confidential from "./confidential"
import Grants from "./grants"

{EncryptionKeyPair, SignatureKeyPair} = Confidential

class Profile

  @fromObject: (object) ->
    {data, keyPairs, grants} = object
    new Profile
      data: data
      grants: Grants.fromObject {grants, keyPairs}
      keyPairs:
        encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
        signature: SignatureKeyPair.from "base64", keyPairs.signature

  @toObject: (profile) ->
    {keyPairs, data, grants} = profile
    data: data
    grants: Grants.toObject grants
    keyPairs:
      encryption: keyPairs.encryption.to "base64"
      signature: keyPairs.signature.to "base64"

  @create: (data) ->
    keyPairs =
      encryption: await EncryptionKeyPair.create()
      signature: await SignatureKeyPair.create()
    new Profile
      data: data
      grants: Grants.create {keyPairs}
      keyPairs: keyPairs

  @update: (profile, handler) ->
    await handler.call profile
    Profiles.store()

  constructor: ({@data = {}, @keyPairs, @grants}) ->

  store: -> Profiles.commit()

  update: (handler) -> Profile.update @, handler

Profiles =

  create: (data) ->
    profile = await Profile.create data
    (@_profiles ?= []).push profile
    @commit()
    profile

  commit: -> if @profiles? then @store @profiles

  load: ->
    if (json = localStorage.getItem "profiles")?
      (Profile.fromObject data) for data in JSON.parse json

  store: (profiles) ->
    localStorage.setItem "profiles",
      JSON.stringify ((Profile.toObject profile) for profile in @_profiles)


properties Profiles,

  all:
    get: -> @_profiles ?= @load()

  current:
    get: ->
      @_current ?= do ->
        if (profiles = Profiles.all)?
          for profile in profiles
            return profile if profile.current == true
          # we should never reach here
          throw "local-credentials: no current profile"

    set: (profile) ->
      profile.current = true
      @_current = profile
      @commit()
      profile


export default Profiles
