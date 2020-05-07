import assert from "assert"
import {print, test, success} from "amen"
import capability from "panda-capability"
import Confidential from "../src/confidential"

{SharedKey, SignatureKeyPair, EncryptionKeyPair,
  Message, Envelope, encrypt} = Confidential
{Directory, issue} = capability Confidential

import Profiles from "../src"
import "./local-storage"

do ->

  APIKeyPairs =
    encryption: await EncryptionKeyPair.create()
    signature: await SignatureKeyPair.create()

  print await test "Local Credentials",  [

    test "Profile", [

      test "Create", ->
        alice = await Profiles.create nickname: "alice"
        profiles = Profiles.all
        assert.equal profiles[0], alice

      test "Current", ->
        alice = await Profiles.create nickname: "alice"
        Profiles.current = alice
        assert.equal true, alice.current

      test "Update", ->
        alice = await Profiles.create nickname: "alice"
        await alice.update -> @data.nickname = "bob"
        # force deserialize to make sure we commited the change
        # this is not part of the interface
        Profiles._profiles = undefined
        assert.equal "bob", Profiles.all[2].data.nickname

    ]

    test "Grants", await do ->

      alice = await Profiles.create nickname: "alice"

      [

        await test "Receive", ->

          directory = await issue APIKeyPairs.signature, alice.keyPairs.signature.publicKey, [
            template: "/profiles/alice/foo"
            methods: ["OPTIONS", "POST"]
          ,
            template: "/profiles/alice/bar/{baz}"
            methods: ["OPTIONS", "GET", "PUT"]
          ]

          sharedKey = SharedKey.create APIKeyPairs.encryption.privateKey,
            alice.keyPairs.encryption.publicKey

          envelope = await encrypt sharedKey,
            Message.from "bytes", directory.to "bytes"

          alice.grants.receive (APIKeyPairs.encryption.publicKey.to "base64"),
            envelope.to "base64"

          assert alice.grants.directory

        test "Exercise", ->

          assert alice.grants.exercise
            path: "/profiles/alice/foo"
            method: "post"
            parameters: {}

          assert alice.grants.exercise
            path: "/profiles/alice/bar/fubar"
            method: "put"
            parameters: baz: "fubar"

          assert !alice.grants.exercise
            path: "/profiles/alice/bar/fubar"
            method: "post"
            parameters: baz: "fubar"

      ]

  ]

  process.exit if success then 0 else 1
