-- PASSWORD_DEFAULT hashes need more room than the original plain-text values.
-- Run this before deploying the updated user.php endpoint.
ALTER TABLE users MODIFY password VARCHAR(255) NOT NULL;
