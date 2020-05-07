import {tee} from "panda-garden"
import Confidential from "./confidential"
import Grants from "./grants"

{EncryptionKeyPair, SignatureKeyPair} = Confidential

class Profile

  constructor: ({@data = {}, @keyPairs, @grants}) ->

  @fromObject: (object) ->
    {data, keyPairs, grants} = profile
    new Profile
      data: data
      grants: Grants.fromObject {grants, keyPairs}
      keyPairs:
        encryption: EncryptionKeyPair.from "base64", keyPairs.encryption
        signature: SignatureKeyPair.from "base64", keyPairs.signature

  @toObject: tee (profile) ->
    {keyPairs, data, grants} = profile
    data: data
    grants: Grants.toObject grants if grants?
    keyPairs:
      encryption: keyPairs.encryption.to "base64"
      signature: keyPairs.signature.to "base64"

  @create: (data) ->
    new Profile
      data: data
      keyPairs:
        encryption: await EncryptionKeyPair.create()
        signature: await SignatureKeyPair.create()

export default Profile
