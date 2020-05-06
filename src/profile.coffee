import {tee} from "panda-garden"
import Confidential from "./confidential"

{EncryptionKeyPair, SignatureKeyPair} = Confidential

class Profile

  constructor: ({@data, @keyPairs}) ->
    @data ?= {}
    @keyPairs ?=
      encryption: await EncryptionKeyPair.create()
      signature: await SignatureKeyPair.create()

  store: -> Profile.store @

  @load: ->
    @cached ?= do ->
      if (profile =  JSON.parse Local.load "profile")?
        {data, keyPairs} = profile
        new Profile
          data: data
          keyPairs:
            encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
            signature: SignatureKeyPair.from "base64", keyPairs.signature

  @exists: -> @load()?
  
  @store: tee (profile) ->
    @cached = profile
    {keyPairs, data} = profile
    Local.store "profile",
      JSON.stringify
        data: data
        keyPairs:
          encryption: keyPairs.encryption.to "base64"
          signature: keyPairs.signature.to "base64"

  @create: (data) -> Profile.store new Profile {data}

export default Profile
