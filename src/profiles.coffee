import {tee} from "panda-garden"
import Profile from "./profile"

Profiles =

  create: (data) ->
    (@profiles ?= []).push await Profile.create data
    @store()

  get: ->
    @profiles ?= if (json = localStorage.getItem "profiles")?
      Profile.fromObject data for data in JSON.parse json

  store: ->
    if @profiles?
      localStorage.setItem "profiles",
        JSON.stringify do =>
          for profile in @profiles
            Profile.toObject profile

Object.defineProperty Profiles, "current",
  get: ->
    @_current ?= do ->
      if (profiles = Profiles.load())?
        for profile in profiles
          return profile if profile.current == true
        # we should never reach here
        throw "local-credentials: no current profile"
  set: tee (profile) ->
    profile.current = true
    @_current = profile
    @store()

# add this here to avoid circular dependency
Profile::store = -> Profiles.store()


export default Profiles
