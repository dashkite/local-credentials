import {print, test, success} from "amen"
import Profiles from "../src"
import "./local-storage"

do ->

  print await test "Local Credentials",  [

    test "Loads as a module", ->
      await Profiles.create nickname: "alice"
      console.log await Profiles.get()

  ]

  process.exit if success then 0 else 1
