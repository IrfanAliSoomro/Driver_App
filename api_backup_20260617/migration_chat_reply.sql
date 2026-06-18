-- Reply-to-message support for chat
-- Run once: mysql -u user -p aladgxlf_db2 < migration_chat_reply.sql

USE `aladgxlf_db2`;

ALTER TABLE `chat_messages`
  ADD COLUMN `reply_to_message_id` BIGINT UNSIGNED NULL DEFAULT NULL AFTER `text`,
  ADD KEY `idx_chat_messages_reply_to` (`reply_to_message_id`),
  ADD CONSTRAINT `fk_chat_messages_reply_to`
    FOREIGN KEY (`reply_to_message_id`) REFERENCES `chat_messages` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
