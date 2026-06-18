-- Run once on existing databases that still use ENUM for chat_messages.group_name
-- New installs: schema.sql already uses VARCHAR(64)

USE `aladgxlf_db2`;

ALTER TABLE `chat_messages`
  MODIFY COLUMN `group_name` VARCHAR(64) NOT NULL;
