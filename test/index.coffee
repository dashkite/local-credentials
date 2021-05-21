import assert from "assert"
import {print, test, success} from "amen"

import "fake-indexeddb/auto"
# import CustomEvent from "./custom-event"
# global.CustomEvent = CustomEvent

import capability from "@dashkite/cobalt"
import {Confidential, Capability} from "../src/helpers"

{SharedKey, SignatureKeyPair, EncryptionKeyPair, PublicKey,
  Message, Envelope, encrypt} = Confidential
{Directory, issue, bundle} = Capability

import Profile from "../src"
import "./local-storage"

reload = ->
  # force deserialize to make sure we commited the change
  # this is not part of the interface

same = (a, b) -> a.address == b.address

host = "https://localhost"

do ->

  print await test "Zinc: Local Profiles",  [

    await test "Profile", await do ->

      alice = await Profile.create host, nickname: "alice"

      [

        await test "Confidential", ->
          assert Profile.Confidential

        await test "Create", ->
          profiles = await Profile.all
          assert same profiles[0], alice

        await test "Current", ->
          assert !(await Profile.current)
          Profile.current = alice
          assert same alice, await Profile.current

        # need await here b/c of the reload in the next test
        # otherwise the reload happens before the update commits
        # this wouldn't normally happen because a reload only happens
        # when the page reloads.
        await test "Update", ->
          await alice.update -> @data.friends = [ "bob" ]
          alice_ = await Profile.load host, alice.address
          assert.equal "bob", alice_.data.friends[0]

        await test "Serialize", [

          await test "From Address", ->
            alice_ = await Profile.load host, alice.address
            assert.equal "alice", alice_.data.nickname

          await test "From JSON", ->
            alice = await Profile.current
            alice_ = Profile.fromJSON alice.toJSON()
            assert same alice, alice_

          await test "Public Keys", ->
            alice = await Profile.current
            keys = alice.publicKeys
            assert.equal keys.encryption,
              alice.keyPairs.encryption.publicKey.to "base64",
            assert.equal keys.signature,
              alice.keyPairs.signature.publicKey.to "base64",
        ]

        await test "Events", ->
          updated = undefined
          Profile.on update: (profile) -> updated = profile
          await alice.store()
          assert same alice, updated

        await test "Delete", ->
          await alice.delete()
          assert !await Profile.load host, alice.address

        await test "Scoped Identity", ->
          originals = await Promise.all [
            Profile.create "#{host}:3000", nickname: "alice3000"
            Profile.create "#{host}:8000", nickname: "alice8000"
          ]
          copies = await Promise.all [
            Profile.load "#{host}:3000", originals[0].address
            Profile.load "#{host}:8000", originals[1].address
          ]
          assert.equal originals[0].address, copies[0].address
          assert.equal originals[1].address, copies[1].address
          assert.notEqual copies[0].address, copies[1].address

        await test "Adjunct Identity", ->
          alice = await Profile.create host, nickname: "alice"
          await alice.createAdjunct "#{host}:3000", name: "alice"
          assert.equal "alice",
            (await alice.getAdjunct "#{host}:3000").data.name
    ]

    test "Grants", await do ->

      alice = await Profile.create host, nickname: "alice"

      [

        await test "Receive", ->

          APIKeyPairs =
            encryption: await EncryptionKeyPair.create()
            signature: await SignatureKeyPair.create()

          expiration = do ->
            d = new Date()
            d.setMinutes d.getMinutes() + 2
            d.toISOString()

          directory = bundle [
            issue APIKeyPairs.signature,
              template: "/profiles/alice/foo"
              methods: [ "POST" ]
              tolerance:
                seconds: 5
              expires: expiration
              issuer:
                literal: APIKeyPairs.signature.publicKey.to "base64"
              claimant:
                literal: alice.keyPairs.signature.publicKey.to "base64"

            issue APIKeyPairs.signature,
              template: "/profiles/alice/bar/{baz}"
              methods: [ "GET", "PUT" ]
              tolerance:
                seconds: 5
              expires: expiration
              issuer:
                literal: APIKeyPairs.signature.publicKey.to "base64"
              claimant:
                literal: alice.keyPairs.signature.publicKey.to "base64"
          ]

          sharedKey = SharedKey.create APIKeyPairs.encryption.privateKey,
            alice.keyPairs.encryption.publicKey

          envelope = await encrypt sharedKey,
            Message.from "bytes", directory.to "bytes"

          await alice.receive (APIKeyPairs.encryption.publicKey.to "base64"),
            envelope.to "base64"

          assert alice.grants.directory

        test "Lookup", ->

          assert alice.lookup
            path: "/profiles/alice/foo"
            method: "post"
            parameters: {}

          assert alice.lookup
            path: "/profiles/alice/bar/fubar"
            method: "put"
            parameters: baz: "fubar"

          assert !alice.lookup
            path: "/profiles/alice/bar/fubar"
            method: "post"
            parameters: baz: "fubar"

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
          alice_ = await Profile.load host, alice.address
          assert alice_.exercise
            path: "/profiles/alice/bar/fubar"
            method: "put"
            parameters: baz: "fubar"

      ]

  ]

  process.exit if success then 0 else 1
