# Local Credentials

_Manage profile and Web capabilities using Local Storage._

## Scenarios

#### Create A New Profile

```coffeescript
Profile.create nickname: "alice"
```

#### Load A Profile

```coffeescript
alice = Profile.load()
```

#### Check To See If A Profile Has Been Defined

```coffeescript
if !Profile.exists()
  browse "register"
```

#### Update And Store A Profile

```coffeescript
profile.data.nickname = "bob"
profile.store()
```

#### Add Grants To The Grants Directory

The `key` and `data` variables are the sender’s public encryption key and the ciphertext of the grants.

```coffeescript
grants = Grants.load()
directory = Grants.receieve key, ciphertext 
grants.add directory
```

> **Important ▸ **The grants directory will automatically initialize itself the first time its referenced.

#### Exercise A Grant For Use With A Request

```coffeescript
grants = Grants.load()
authorization = grants.exercise request
```

## API

### Profile

#### *Profile.create data ⇢ profile*

Creates a profile with the given data and stores it in LocalStorage. Automatically generates encryption and signature keypairs for use with the profile. Returns a promise for the profile.

#### *Profile.load → profile*

Loads profile from LocalStorage. Returns `undefined` if no profile is stored.

#### *Profile.exists → boolean*

Returns true if a profile is stored locally.

#### *Profile.store profile → profile*

Stores profile in LocalStorage. Useful for storing a profile after updating it.

```coffeescript
profile.data.nickname = "alice"
Profile.store profile
```

#### *store → profile*

Convenience method for Profile.store.

### Grants

#### *Grants.load → grants*

Loads grants from LocalStorage.

#### *Grants.store ⇢ grants*

Stores grants in LocalStorage. Returns a promise for the stored grants.

#### *Grants.exercise grants, request → assertion*

Does a lookup for a grant suitable for the given request. If found, the grant is signed using the Profile signature key pair. Returns the signed grant. The request argument must provide `path`, `parameters`, and `method` properties.

#### *Grants.add grants, directory ⇢ grants*

Adds new grants to grants and stores them in LocalStorage. Returns a promise for the updated grants.

#### *Grants.encrypt directory ⇢ base64*

Encrypts the directory of grants using the profile encryption key pair. Returns a promise for the encrypted directory as base64 ciphertext.

#### *Grants.decrypt base64 → directory*

Decrypts a directory of grants from base64 ciphertext using the Profile key pairs.

#### *Grants.receive key, base64 → directory*

Decrypts a directory of grants from base64 ciphertext using the given base64 encoded sender public encryption key.