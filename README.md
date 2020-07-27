# Zinc

_Manage profile and Web capabilities using IndexedDB._

## Install

`npm i @dashkite/zinc`

Use with your favorite bundler.

## Scenarios

#### List All Profiles

If you want to allow for multiple identities, you’ll need a way to list the choices.

```coffeescript
profiles = await Profile.all
```

#### Create A New Profile

```coffeescript
alice = await Profile.create authority, nickname: "alice"
```

#### Get Current Profile

```coffeescript
alice = await Profile.current
```

#### Set Current Profile

```coffeescript
Profile.current = alice
```

#### Update And Store A Profile

```coffeescript
await profile.update -> @data.nickname = "alice"
```

#### Create An Adjunct Profile

```coffeescript
await profile.createAdjunct authority, nickname: "alice"
```

#### Get An Adjunct Profile

```coffeescript
await profile.getAdjunct authority
```

#### Listen For Changes To A Profile

```coffeescript
Profile.on update: (profile) -> console.log "Profile [#{profile.address}] updated"
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

Conventions:

- A function or method with a dotted arrow ⇢ yields or returns a Promise
- The `::` indicates the prototype. Ex: `Profile::exercise` is a method, not a class function.

### Profile

#### Property: *Profile.Confidential*

Returns the instance of Confidential used by Zinc to generate key pairs and other cryptographic elements, and to perform cryptographic operations.

#### Function: *Profile.on event-handlers*

Set event handlers for Profile-related events based on the *event-handlers*, which is a dictionary of events and handlers. Handlers should be functions that take an optional _target_ argument.

```coffeescript
Profile.on update: (profile) -> console.log "Profile [#{profile.address}] updated"
```

#### Function: *Profile.dispatch event, value*

Fire a. Profile-related event. You typically do not need to call this directly.

#### Event: *update → profile*

Fired whenever a profile is updated. The updated profile is passed to the event handler.

#### Function: *Profile.create authority, data ⇢ profile*

Creates a profile for a given authority and data and stores it. Automatically generates encryption and signature keypairs for use with the profile. Returns a promise for the profile.

#### Function: *Profile.createAdjunct authority, data ⇢ profile*

Creates a profile using the address for the current profile for a given authority and data and stores it. Automatically generates encryption and signature keypairs for use with the profile. Returns a promise for the profile.

#### Function: *Profile.getAdjunct authority ⇢ profile*

Loads and returns the adjunct profile for given authority. Returns a promise for the profile.

#### Function: *Profile.load authority, address ⇢ profile*

Load the profile corresponding to the given authority and address.

#### Property: *Profile.all ⇢ array*

Returns a promise for an array of all profiles.

#### Property: *Profile.current ⇢ profile*

Gets or sets the current profile. Getter returns a promise for the profile. Returns undefined if the current profile is not set or has been deleted.

#### Method: *Profile::createAdjunct authority, data ⇢ profile*
Convenience method for `Profile.createAdjunct`.

#### Method: *Profile::getAdjunct authority ⇢ profile*
Convenience method for `Profile.getAdjunct`.


#### Method: *Profile::exercise request → claim*

Exercise the grant corresponding to the given claim. Returns a claim (a countersigned grant). The request argument must provide `path`, `parameters`, and `method` properties.

#### Method: *Profile::receive key, ciphertext ⇢ undefined*

Decrypts a directory of grants from base64 ciphertext using the given base64 encoded sender public encryption key, adds them to the profile’s grants directory, and stores the profile.

#### Method: *Profile::update handler ⇢ undefined*

Runs handler bound to profile and stores the profile. Useful for ensuring that profile updates are stored. Promise resolves when the update has been stored.

#### Method: *Profile::delete ⇢ undefined*

Deletes the given profile. If this the current profile, `Profile.current` will return undefined.
