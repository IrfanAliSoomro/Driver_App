-- API2 database schema reconstructed from current API codebase
-- MySQL 8.0+

CREATE DATABASE IF NOT EXISTS `aladgxlf_db2`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `aladgxlf_db2`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `users` (
  `user_id` VARCHAR(128) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `display_name` VARCHAR(255) DEFAULT NULL,
  `photo_url` TEXT DEFAULT NULL,
  `fcm_token` TEXT DEFAULT NULL,
  `latitude` DECIMAL(10,7) DEFAULT NULL,
  `longitude` DECIMAL(10,7) DEFAULT NULL,
  `location_updated_at` DATETIME DEFAULT NULL,
  `last_sign_in` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_last_sign_in` (`last_sign_in`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_users` (
  `user_id` VARCHAR(128) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_admin_users_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blocked_drivers` (
  `user_id` VARCHAR(128) NOT NULL,
  `reason` VARCHAR(500) DEFAULT NULL,
  `blocked_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  KEY `idx_blocked_drivers_blocked_at` (`blocked_at`),
  CONSTRAINT `fk_blocked_drivers_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flight_data` (
  `flight_id` VARCHAR(64) NOT NULL,
  `airline` VARCHAR(255) NOT NULL,
  `flight_number` VARCHAR(50) NOT NULL,
  `destination` VARCHAR(255) NOT NULL,
  `scheduled_time` VARCHAR(32) NOT NULL,
  `status` VARCHAR(100) NOT NULL,
  `gate` VARCHAR(50) DEFAULT NULL,
  `airline_code` VARCHAR(20) DEFAULT NULL,
  `is_arrival` TINYINT(1) NOT NULL DEFAULT 0,
  `last_updated` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`flight_id`),
  KEY `idx_flight_data_scheduled_time` (`scheduled_time`),
  KEY `idx_flight_data_arrival_time` (`is_arrival`, `scheduled_time`),
  KEY `idx_flight_data_flight_number` (`flight_number`),
  KEY `idx_flight_data_airline` (`airline`),
  KEY `idx_flight_data_destination` (`destination`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `price_alerts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(128) NOT NULL,
  `pickup` VARCHAR(255) NOT NULL,
  `dropoff` VARCHAR(255) NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_price_alerts_user_id` (`user_id`),
  KEY `idx_price_alerts_created_at` (`created_at`),
  CONSTRAINT `fk_price_alerts_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `price_alert_likes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `alert_id` BIGINT UNSIGNED NOT NULL,
  `user_id` VARCHAR(128) NOT NULL,
  `type` ENUM('like','dislike') NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_price_alert_likes_alert_user` (`alert_id`, `user_id`),
  KEY `idx_price_alert_likes_alert_id_type` (`alert_id`, `type`),
  KEY `idx_price_alert_likes_user_id` (`user_id`),
  CONSTRAINT `fk_price_alert_likes_alert`
    FOREIGN KEY (`alert_id`) REFERENCES `price_alerts` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_price_alert_likes_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_name` VARCHAR(64) NOT NULL,
  `user_id` VARCHAR(128) NOT NULL,
  `text` TEXT NOT NULL,
  `reply_to_message_id` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_chat_messages_group_created` (`group_name`, `created_at`),
  KEY `idx_chat_messages_user_id` (`user_id`),
  KEY `idx_chat_messages_reply_to` (`reply_to_message_id`),
  CONSTRAINT `fk_chat_messages_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_chat_messages_reply_to`
    FOREIGN KEY (`reply_to_message_id`) REFERENCES `chat_messages` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `suggestions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(128) NOT NULL,
  `driver_name` VARCHAR(255) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `status` ENUM('pending','reviewed','implemented') NOT NULL DEFAULT 'pending',
  `admin_response` TEXT DEFAULT NULL,
  `responded_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_suggestions_user_id` (`user_id`),
  KEY `idx_suggestions_status_created` (`status`, `created_at`),
  CONSTRAINT `fk_suggestions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(128) DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `body` TEXT NOT NULL,
  `data` JSON DEFAULT NULL,
  `type` VARCHAR(100) DEFAULT 'general',
  `is_broadcast` TINYINT(1) NOT NULL DEFAULT 0,
  `sent_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notifications_user_id` (`user_id`),
  KEY `idx_notifications_sent_at` (`sent_at`),
  KEY `idx_notifications_type` (`type`),
  CONSTRAINT `fk_notifications_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `parking_lots` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `latitude` DECIMAL(10,7) NOT NULL,
  `longitude` DECIMAL(10,7) NOT NULL,
  `radius_meters` INT NOT NULL DEFAULT 500,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_parking_lots_name` (`name`),
  KEY `idx_parking_lots_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `active_users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(128) NOT NULL,
  `location_name` VARCHAR(100) NOT NULL,
  `status` ENUM('active','inactive') NOT NULL DEFAULT 'active',
  `last_seen` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_active_users_user_location` (`user_id`, `location_name`),
  KEY `idx_active_users_location_status_last_seen` (`location_name`, `status`, `last_seen`),
  KEY `idx_active_users_last_seen` (`last_seen`),
  CONSTRAINT `fk_active_users_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `app_config` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key` VARCHAR(100) NOT NULL,
  `config_value` TEXT NOT NULL,
  `config_type` ENUM('string','number','boolean','json','coordinates') NOT NULL DEFAULT 'string',
  `environment` ENUM('dev','live','both') NOT NULL DEFAULT 'both',
  `description` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_app_config_env_key` (`environment`, `config_key`),
  KEY `idx_app_config_key_active` (`config_key`, `is_active`),
  KEY `idx_app_config_environment_active` (`environment`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP VIEW IF EXISTS `active_users_count`;
CREATE VIEW `active_users_count` AS
SELECT
  au.location_name,
  COUNT(*) AS active_count
FROM `active_users` au
WHERE au.status = 'active'
  AND au.last_seen > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
GROUP BY au.location_name;

INSERT INTO `parking_lots` (`name`, `latitude`, `longitude`, `radius_meters`, `is_active`)
VALUES
  ('MidwayLot', 41.7867750, -87.7521880, 600, 1),
  ('OhareAlphaLot', 41.9802640, -87.9086070, 700, 1),
  ('OhareDeltaLot', 41.9741620, -87.9073210, 700, 1)
ON DUPLICATE KEY UPDATE
  `latitude` = VALUES(`latitude`),
  `longitude` = VALUES(`longitude`),
  `radius_meters` = VALUES(`radius_meters`),
  `is_active` = VALUES(`is_active`);

SET FOREIGN_KEY_CHECKS = 1;
