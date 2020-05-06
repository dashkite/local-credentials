import {tee} from "panda-garden"
import Confidential from "./confidential"

{EncryptionKeyPair, SignatureKeyPair} = Confidential

class Profile

  constructor: ({@data = {}, @keyPairs, @grants}) ->

  @fromSerialazableObject: (object) ->
    {data, keyPairs, grants} = profile
    new Profile
      data: data
      grants: Grants.fromObject {grants, keyPairs}
      keyPairs:
        encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
        signature: SignatureKeyPair.from "base64", keyPairs.signature

  @toSerializableObject: tee (profile) ->
    {keyPairs, data, grants} = profile
    Local.store "profile",
      JSON.stringify
        data: data
        grants: Grants.toObject grants
        keyPairs:
          encryption: keyPairs.encryption.to "base64"
          signature: keyPairs.signature.to "base64"

  @create: (data) ->
    Profile.store new Profile
      data: data
      keyPairs:
        encryption: await EncryptionKeyPair.create()
        signature: await SignatureKeyPair.create()

export default Profile
