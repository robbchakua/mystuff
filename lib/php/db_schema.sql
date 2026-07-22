-- MyStuff database schema
-- Tested for MySQL 8+ and recent MariaDB releases.

CREATE DATABASE IF NOT EXISTS `rusmark_mystuff`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `rusmark_mystuff`;

CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `userid` VARCHAR(60) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `email` VARCHAR(190) NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('admin', 'observer') NOT NULL DEFAULT 'observer',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_userid_unique` (`userid`),
  UNIQUE KEY `users_email_unique` (`email`),
  KEY `users_role_active_index` (`role`, `is_active`)
) ENGINE=InnoDB;

CREATE TABLE `user_sessions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `token_hash` CHAR(64) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `last_used_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `revoked_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_sessions_token_unique` (`token_hash`),
  KEY `user_sessions_user_expiry_index` (`user_id`, `expires_at`),
  CONSTRAINT `user_sessions_user_fk`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `bins` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT UNSIGNED NULL,
  `created_by` BIGINT UNSIGNED NULL,
  `name` VARCHAR(160) NOT NULL,
  `description` TEXT NULL,
  `image_path` VARCHAR(500) NULL,
  `latitude` DECIMAL(10, 7) NULL,
  `longitude` DECIMAL(10, 7) NULL,
  `color` CHAR(6) NOT NULL DEFAULT 'F44336',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `bins_parent_index` (`parent_id`),
  KEY `bins_created_by_index` (`created_by`),
  CONSTRAINT `bins_parent_fk`
    FOREIGN KEY (`parent_id`) REFERENCES `bins` (`id`)
    ON DELETE RESTRICT,
  CONSTRAINT `bins_creator_fk`
    FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE `bin_permissions` (
  `bin_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `permission` ENUM('view', 'edit') NOT NULL,
  `granted_by` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`bin_id`, `user_id`),
  KEY `bin_permissions_user_index` (`user_id`),
  KEY `bin_permissions_granted_by_index` (`granted_by`),
  CONSTRAINT `bin_permissions_bin_fk`
    FOREIGN KEY (`bin_id`) REFERENCES `bins` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `bin_permissions_user_fk`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `bin_permissions_granter_fk`
    FOREIGN KEY (`granted_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE `items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `bin_id` BIGINT UNSIGNED NOT NULL,
  `created_by` BIGINT UNSIGNED NULL,
  `name` VARCHAR(180) NOT NULL,
  `stored_at` DATE NOT NULL,
  `image_path` VARCHAR(500) NULL,
  `is_multiple` TINYINT(1) NOT NULL DEFAULT 0,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `description` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `items_bin_index` (`bin_id`),
  KEY `items_name_index` (`name`),
  KEY `items_created_by_index` (`created_by`),
  CONSTRAINT `items_bin_fk`
    FOREIGN KEY (`bin_id`) REFERENCES `bins` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `items_creator_fk`
    FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB;
