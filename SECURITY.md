# Security notes

## Required before the next release

1. Rotate the Android signing password and the Google Maps API key that were
   previously committed in the project snapshot. Treat both old values as
   compromised.
2. Restrict the replacement Maps key in Google Cloud to the Android package and
   signing-certificate fingerprint, and enable only the Maps SDKs the app uses.
3. Put the replacement Maps key in `android/local.properties`:

   ```properties
   maps.apiKey=replace-with-the-restricted-key
   ```

4. Copy `android/key.properties.example` to `android/key.properties`, point it
   at the rotated keystore, and fill in the rotated signing credentials.

Both local configuration files and keystores are ignored by Git.
`DadAppVersions.zip` is also ignored because the historical archive may still
contain the retired credentials; keep it private.

## Password migration deployment order

The Flutter client now asks `user.php` to verify credentials and no longer
serializes a password into `SharedPreferences`.

1. Back up the database.
2. Run `lib/php/migrations/001_password_hashes.sql`.
3. Deploy `lib/php/user.php`.
4. Deploy the rebuilt Flutter client.

New passwords use PHP's `password_hash`. An existing plain-text value is
accepted once after a successful login and immediately replaced with a hash.
After active accounts have migrated, remove the legacy `hash_equals` branch in
`verify_password_and_upgrade`.

## Remaining backend limitation

`post.php` now uses prepared statements, validates uploads, scopes item and
location mutations by both record ID and user ID, and avoids returning SQL
details. It still trusts the client-provided user ID because the old API has no
session-token protocol. Do not treat that endpoint as fully authorized.

The smallest clean follow-up is to move authentication, the three relational
tables, and item images to Supabase Auth, Postgres with row-level-security
policies, and Storage. That preserves the existing relational model while
removing the custom PHP transport.
