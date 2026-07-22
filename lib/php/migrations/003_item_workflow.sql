-- Item statuses and movement/audit history for an existing MyStuff database.
USE `rusmark_mystuff`;

ALTER TABLE `items`
  ADD COLUMN `status` ENUM('missing', 'in_use', 'in_location')
    NOT NULL DEFAULT 'in_location' AFTER `tags`,
  ADD KEY `items_status_index` (`status`);

CREATE TABLE `item_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `item_id` BIGINT UNSIGNED NOT NULL,
  `changed_by` BIGINT UNSIGNED NULL,
  `changed_by_name` VARCHAR(120) NOT NULL,
  `action` VARCHAR(40) NOT NULL,
  `from_bin_id` BIGINT UNSIGNED NULL,
  `to_bin_id` BIGINT UNSIGNED NULL,
  `from_bin_name` VARCHAR(160) NULL,
  `to_bin_name` VARCHAR(160) NULL,
  `from_status` VARCHAR(20) NULL,
  `to_status` VARCHAR(20) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `item_history_item_date_index` (`item_id`, `created_at`),
  KEY `item_history_actor_index` (`changed_by`),
  CONSTRAINT `item_history_item_fk`
    FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `item_history_actor_fk`
    FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `item_history_from_bin_fk`
    FOREIGN KEY (`from_bin_id`) REFERENCES `bins` (`id`)
    ON DELETE SET NULL,
  CONSTRAINT `item_history_to_bin_fk`
    FOREIGN KEY (`to_bin_id`) REFERENCES `bins` (`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- Give existing items a starting point in their history.
INSERT INTO `item_history` (
  `item_id`, `changed_by`, `changed_by_name`, `action`,
  `to_bin_id`, `to_bin_name`, `to_status`, `created_at`
)
SELECT
  i.id,
  i.created_by,
  COALESCE(u.name, 'Existing data'),
  'imported',
  i.bin_id,
  b.name,
  i.status,
  i.created_at
FROM `items` i
JOIN `bins` b ON b.id = i.bin_id
LEFT JOIN `users` u ON u.id = i.created_by;

-- Email-only login is enforced by the API. Before deploying user.php, make
-- sure this query returns no rows; assign real unique emails where necessary.
SELECT `id`, `userid`, `name`
FROM `users`
WHERE `email` IS NULL OR TRIM(`email`) = '';

-- Once the query above returns no rows, enforce the same database rule used by
-- fresh installations:
-- ALTER TABLE `users`
--   MODIFY COLUMN `email` VARCHAR(190) NOT NULL;
