import assert from "assert"
import {print, test, success} from "amen"
import Profiles from "../src"
import "./local-storage"

do ->

  print await test "Local Credentials",  [

    test "Create Profile", ->
      alice = await Profiles.create nickname: "alice"
      profiles = Profiles.all
      assert.equal profiles[0], alice

    test "Current Profile", ->
      alice = await Profiles.create nickname: "alice"
      Profiles.current = alice
      assert.equal true, alice.current

    test "Update Profile", ->
      alice = await Profiles.create nickname: "alice"
      await alice.update -> @data.nickname = "bob"
      # force deserialize to make sure we commited the change
      # this is not part of the interface
      Profiles._profiles = undefined
      assert.equal "bob", Profiles.all[2].data.nickname

  ]

  process.exit if success then 0 else 1
