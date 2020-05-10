# Zinc

_Manage profile and Web capabilities using IndexedDB._

## Scenarios

#### List All Profiles

If you want to allow for multiple identities, you’ll need a way to list the choices.

```coffeescript
profiles = await Profile.all
```

#### Create A New Profile

```coffeescript
alice = await Profile.create nickname: "alice"
```

#### Get Current Profile

```coffeescript
alice = await Profiles.current
```

#### Set Current Profile

```coffeescript
Profiles.current = alice
```

#### Update And Store A Profile

```coffeescript
await profile.update -> @data.nickname = "alice"
```

#### Add Grants To The Grants Directory

The `key` and `ciphertext` variables are the sender’s public encryption key and the Base64 ciphertext of the grants.

```coffeescript
alice = await Profile.current
await alice.receive key, ciphertext
```

#### Exercise A Grant For Use With A Request

```coffeescript
alice = await Profile.current
claim = grants.exercise request
```

#### Delete A Profile

```coffeescript
alice = await Profile.current
await alice.delete()
```



## API

### Profile

#### Function: *Profile.create data ⇢ profile*

Creates a profile with the given data and stores it. Automatically generates encryption and signature keypairs for use with the profile. Returns a promise for the profile.

#### Property: *Profile.all ⇢ array*

Returns a promise for an array of all profiles.

#### Property: *Profile.current ⇢ profile*

Gets or sets the current profile. Getter returns a promise for the profile. Returns undefined if the current profile is not set or has been deleted.

#### Method: *Profile::exercise request → claim*

Exercise the grant corresponding to the given claim. Returns a claim (a countersigned grant). The request argument must provide `path`, `parameters`, and `method` properties.

#### Method: *Profile::receive key, ciphertext ⇢ undefined*

Decrypts a directory of grants from base64 ciphertext using the given base64 encoded sender public encryption key, adds them to the profile’s grants directory, and stores the profile.

#### Method: *Profile::update handler ⇢ undefined*

Runs handler bound to profile and stores the profile. Useful for ensuring that profile updates are stored. Promise resolves when the update has been stored.

#### Method: *Profile::delete ⇢ undefined*

Deletes the given profile. If this the current profile, `Profile.current` will return undefined.