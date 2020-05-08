# Local Credentials

_Manage profile and Web capabilities using Local Storage._

## Scenarios

#### List All Profiles

If you want to allow for multiple identities, you’ll need a way to list the choices.

```coffeescript
Profiles.all
```

#### Create A New Profile

```coffeescript
alice = await Profiles.create nickname: "alice"
```

#### Get Current Profile

```coffeescript
Profiles.current
```

#### Set Current Profile

```coffeescript
Profiles.current = alice
```

#### Update And Store A Profile

```coffeescript
profile.update -> @data.nickname = "bob"
```

#### Add Grants To The Grants Directory

The `key` and `data` variables are the sender’s public encryption key and the ciphertext of the grants.

```coffeescript
grants = Profiles.current.grants
directory = grants.receive key, data
```

#### Exercise A Grant For Use With A Request

```coffeescript
grants = Profile.current.grants
authorization = grants.exercise request
```

## API

### Profiles

#### *Profiles.create data ⇢ profile*

Creates a profile with the given data and stores it in LocalStorage. Automatically generates encryption and signature keypairs for use with the profile. Returns a promise for the profile.

#### *Profiles.commit → undefined*

Writes profils to LocalStorage. You won’t typically need to call this directly.

#### *Profiles.all*

Reference an array of all profiles. Implicitly loads them from LocalStorage if necessary.

#### *Profile.current*

References the current profile. Implicitly loads profiles if they haven’t already been loaded.

### Grants

#### *Grants.exercise grants, request → assertion*

Does a lookup for a grant suitable for the given request. If found, the grant is signed using the Profile signature key pair. Returns the signed grant. The request argument must provide `path`, `parameters`, and `method` properties.

#### *Grants.add grants, directory → grants*

Adds new grants to grants and stores them in LocalStorage. Returns the updated grants. You won’t typically need to call this directly.

#### *Grants.receive grants, key, ciphertext → directory*

Decrypts a directory of grants from base64 ciphertext using the given base64 encoded sender public encryption key.

#### *receive key, ciphertext ⇢ grants*

Convenience method for Grants.add.

#### *exercise request → authorization*

Convenience method for Grants.exercise.
