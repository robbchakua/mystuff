# MyStuff PHP API deployment

## Server requirements

- PHP 8.1 or newer with PDO MySQL and Fileinfo enabled
- MySQL 8+ or a recent MariaDB release
- HTTPS (the app must never send credentials or session tokens over HTTP)

## Fresh database setup

1. Import `db_schema.sql` through phpMyAdmin or the MySQL command line. It
   creates and selects the `rusmark_mystuff` database.
2. In the hosting panel, create a new MySQL/MariaDB user with a new random
   password and grant it only `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on
   `rusmark_mystuff`. Do not reuse an old database account. If your host allows
   SQL account management, the equivalent commands are:

   ```sql
   CREATE USER 'mystuff_app'@'localhost' IDENTIFIED BY 'REPLACE_WITH_A_LONG_RANDOM_PASSWORD';
   GRANT SELECT, INSERT, UPDATE, DELETE ON rusmark_mystuff.* TO 'mystuff_app'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. Copy `db.php.example` to `db.php` on the server.
4. Put that new database username and password in `db.php`, or supply the
   documented `MYSTUFF_DB_*` environment variables.
5. Upload `common.php`, `user.php`, `post.php`, and `.htaccess` to the HTTPS
   directory currently used by `https://rusmark.io.ke`.
6. Ensure PHP can create and write `images/bins` and `images/items`. The API
   creates those folders with restrictive permissions on the first upload.

After the new API works, revoke the old database accounts through the hosting
panel. Database accounts are separate from the app's `users` table.

The first account created through the app becomes the initial administrator.
After that, account creation requires a logged-in administrator token. There
is therefore no permanently open public registration endpoint.

## Add item tags to an existing database

If the database already exists, run `migrations/002_item_tags.sql`, or execute:

```sql
USE `rusmark_mystuff`;
ALTER TABLE `items`
  ADD COLUMN `tags` VARCHAR(1000) NOT NULL DEFAULT '[]' AFTER `description`;
```

Then upload the updated `post.php`. Fresh installations using `db_schema.sql`
already include the column. Tags are stored as a JSON array in this compatible
text column; the API validates and returns them as an array.

## Access rules

- Administrators can read and edit all bins, manage team accounts, and grant
  or revoke bin access.
- Observers see only bins they have been granted access to.
- A grant on a bin is inherited by every descendant bin. An `edit` grant also
  allows creating sub-bins and creating, moving, editing, or deleting items in
  that branch.
- Top-level bins can only be created by administrators.
- Item `bin_id` is non-null in the database, so an item can never exist without
  a bin.

Do not upload `db_schema.sql`, `db.php.example`, or this README to a public
directory unless the included Apache rules are active. On Nginx, configure the
equivalent deny rules in the site configuration.
