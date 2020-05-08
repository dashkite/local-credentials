import {properties} from "panda-parchment"
import {tee} from "panda-garden"
import Confidential from "./confidential"
import Grants from "./grants"
import Profile from "./profile"

class Manager

  constructor: -> @all = Profiles.load()

  add: (profile) ->
    @all.push profile
    Profile.store profile
    Profiles.store @all
    @

  properties @::,
    current:
      get: ->
        @_current ?= do =>
          if (key = localStorage.getItem "profile/current")?
            for profile in @all
              return profile if profile.key == key

      set: (profile) ->
        localStorage.setItem "profile/current", profile.key
        @_current = profile        

class Profiles

  @load: ->
    if (json = localStorage.getItem "profiles")?
      (Profile.load key) for key in JSON.parse json
    else []

  @store: (profiles) ->
    localStorage.setItem "profiles",
      JSON.stringify (profile.key for profile in profiles)

  @create: (data) -> @add await Profile.create data

  @add: (profile) -> await @manager.add profile ; profile

  properties @,
    manager: get: -> @_manager ?= new Manager
    all: get: -> @manager.all
    current:
      get: -> @manager.current
      set: (profile) -> @manager.current = profile


export default Profiles
