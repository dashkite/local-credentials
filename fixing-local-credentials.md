# Fixing Local Credentials

Store all profiles in one JSON element.

```coffeescript
# list all nicknames for stored profiles
profiles = Profiles.load()
profile.data.nickname for profile in profiles
```

The current profile address (public encryption key) is stored as part of the Profiles object. So we can also say:

```coffeescript
Profiles.current
```

The Profile object becomes a shorthand for accessing `Profile.current`.

```coffeescript
# this is the same as Profiles.current.data
Profile.data
# similarly, we can just access the grants
Profile.grants
```

Changing the current profile just means using the setter on `Profile.current`:

```coffeescript
Profiles.current = profile
```

Profiles are tied to the public encryption key. Changing that means basically creating a new profile.

Storing a profile just means storing all the profiles. Loading a profile is no longer a thing.

We hang grants off a profile. The stage is pretty well set for this because we’ve already split out the encrypt/decrypt part. So we can just add that to the serialization for a Profile.

The Grants interface is still there. So you can still write:

```coffeescript
Grants.add Profile.grants, directory
```

or:

```coffeescript
Profile.grants.add directory
```

or (for a given profile instance aside from the current one):

```coffeescript
profile.grants.exercise request
```

and so on.

