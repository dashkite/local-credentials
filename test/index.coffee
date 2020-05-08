import assert from "assert"
import {print, test, success} from "amen"
import capability from "panda-capability"
import Confidential from "../src/confidential"

{SharedKey, SignatureKeyPair, EncryptionKeyPair,
  Message, Envelope, encrypt} = Confidential
{Directory, issue} = capability Confidential

import Profiles from "../src"
import "./local-storage"

reload = ->
  # force deserialize to make sure we commited the change
  # this is not part of the interface
  Profiles._manager = undefined

same = (a, b) ->
  (a.keyPairs.encryption.publicKey.to "base64") ==
    (b.keyPairs.encryption.publicKey.to "base64")

do ->

  APIKeyPairs =
    encryption: await EncryptionKeyPair.create()
    signature: await SignatureKeyPair.create()

  print await test "Local Credentials",  [

    await test "Profile", await do ->

      alice = await Profiles.create nickname: "alice"

      [

        test "Create", ->
          assert.equal Profiles.all[0], alice

        test "Current", ->
          Profiles.current = alice
          assert same alice, Profiles.current

        # need await here b/c of the reload in the next test
        # otherwise the reload happens before the update commits
        # this wouldn't normally happen because a reload only happens
        # when the page reloads.
        await test "Update", ->
          await alice.update -> @data.friends = [ "bob" ]
          assert.equal "bob", alice.data.friends[0]

        test "Serialize", ->
          reload()
          assert.equal "alice", Profiles.current.data.nickname

    ]

    test "Grants", await do ->

      alice = await Profiles.create nickname: "alice"

      [

        await test "Receive", ->

          directory = await issue APIKeyPairs.signature,
            alice.keyPairs.signature.publicKey,
            [
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

        test "Serialize", ->
          reload()
          count = 0
          for profile in Profiles.all
            if same profile, alice
              count++
              assert profile.grants.exercise
                path: "/profiles/alice/bar/fubar"
                method: "put"
                parameters: baz: "fubar"
          assert.equal 1, count

      ]

  ]

  process.exit if success then 0 else 1
