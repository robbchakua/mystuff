-- Run this only on an existing MyStuff database.
USE `rusmark_mystuff`;

ALTER TABLE `items`
  ADD COLUMN `tags` VARCHAR(1000) NOT NULL DEFAULT '[]' AFTER `description`;
