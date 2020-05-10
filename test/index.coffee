import "fake-indexeddb/auto"
import assert from "assert"
import {print, test, success} from "amen"
import capability from "panda-capability"
import {Confidential, Capability} from "../src/helpers"

{SharedKey, SignatureKeyPair, EncryptionKeyPair,
  Message, Envelope, encrypt} = Confidential
{Directory, issue} = Capability

import Profile from "../src"
import "./local-storage"

reload = ->
  # force deserialize to make sure we commited the change
  # this is not part of the interface

same = (a, b) -> a.address == b.address


do ->

  print await test "Zinc: Local Profiles",  [

    await test "Profile", await do ->

      alice = await Profile.create nickname: "alice"

      [

        await test "Create", ->
          profiles = await Profile.all
          assert same profiles[0], alice

        await test "Current", ->
          Profile.current = alice
          assert same alice, await Profile.current

        # need await here b/c of the reload in the next test
        # otherwise the reload happens before the update commits
        # this wouldn't normally happen because a reload only happens
        # when the page reloads.
        await test "Update", ->
          await alice.update -> @data.friends = [ "bob" ]
          alice_ = await Profile.load alice.address
          assert.equal "bob", alice_.data.friends[0]

        await test "Serialize", ->
          alice_ = await Profile.load alice.address
          assert.equal "alice", alice_.data.nickname

        test "Delete", ->
          await alice.delete()
          assert !await Profile.load alice.address
    ]

    test "Grants", await do ->

      alice = await Profile.create nickname: "alice"

      [

        await test "Receive", ->

          APIKeyPairs =
            encryption: await EncryptionKeyPair.create()
            signature: await SignatureKeyPair.create()

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

          await alice.receive (APIKeyPairs.encryption.publicKey.to "base64"),
            envelope.to "base64"

          assert alice.grants.directory

        test "Exercise", ->

          assert alice.exercise
            path: "/profiles/alice/foo"
            method: "post"
            parameters: {}

          assert alice.exercise
            path: "/profiles/alice/bar/fubar"
            method: "put"
            parameters: baz: "fubar"

          assert !alice.exercise
            path: "/profiles/alice/bar/fubar"
            method: "post"
            parameters: baz: "fubar"

        test "Serialize", ->
          alice_ = await Profile.load alice.address
          assert alice_.exercise
            path: "/profiles/alice/bar/fubar"
            method: "put"
            parameters: baz: "fubar"

      ]

  ]

  process.exit if success then 0 else 1
