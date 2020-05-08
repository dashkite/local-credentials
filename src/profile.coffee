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
      grants: Grants.load grants.key
      keyPairs:
        encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
        signature: SignatureKeyPair.from "base64", keyPairs.signature

  @toObject: (profile) ->
    {keyPairs, data, grants} = profile
    data: data
    grants: key: grants.key
    keyPairs:
      encryption: keyPairs.encryption.to "base64"
      signature: keyPairs.signature.to "base64"

  @create: (data) ->
    new Profile
      data: data
      keyPairs:
        encryption: await EncryptionKeyPair.create()
        signature: await SignatureKeyPair.create()

  @load: (key) ->
    Profile.fromObject JSON.parse localStorage.getItem key

  @store: tee (profile) ->
    localStorage.setItem profile.key,
      JSON.stringify Profile.toObject profile

  @update: tee (profile, handler) ->
    await handler.call profile
    Profile.store profile

  constructor: ({@data = {}, @keyPairs, @grants}) ->
    @grants ?= Grants.create()
    @grants.profile = @
    Grants.store @grants

  update: (handler) -> Profile.update @, handler

  properties @::,
    address: get: -> @keyPairs.encryption.publicKey.to "base64"
    key: get: -> "profile/#{@address}"

export default Profile
