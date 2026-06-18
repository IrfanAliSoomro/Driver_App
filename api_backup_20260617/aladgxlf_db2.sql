-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 03, 2026 at 01:32 AM
-- Server version: 10.6.24-MariaDB-cll-lve
-- PHP Version: 8.4.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `aladgxlf_db2`
--

-- --------------------------------------------------------

--
-- Table structure for table `active_users`
--

CREATE TABLE `active_users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` varchar(128) NOT NULL,
  `location_name` varchar(100) NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `last_seen` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `active_users`
--

INSERT INTO `active_users` (`id`, `user_id`, `location_name`, `status`, `last_seen`, `created_at`) VALUES
(27, '103343709493359555007', 'MidwayLot', 'active', '2026-05-06 09:14:52', '2026-05-06 08:54:48'),
(44, '106003247170311016658', 'OhareAlphaLot', 'active', '2026-05-20 04:39:06', '2026-05-20 04:39:06');

-- --------------------------------------------------------

--
-- Stand-in structure for view `active_users_count`
-- (See below for the actual view)
--
CREATE TABLE `active_users_count` (
`location_name` varchar(100)
,`active_count` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `admin_users`
--

CREATE TABLE `admin_users` (
  `user_id` varchar(128) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admin_users`
--

INSERT INTO `admin_users` (`user_id`, `created_at`) VALUES
('103343709493359555007', '2026-04-20 11:05:09'),
('105861633310543857309', '2026-04-21 16:47:37');

-- --------------------------------------------------------

--
-- Table structure for table `app_config`
--

CREATE TABLE `app_config` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `config_key` varchar(100) NOT NULL,
  `config_value` text NOT NULL,
  `config_type` enum('string','number','boolean','json','coordinates') NOT NULL DEFAULT 'string',
  `environment` enum('dev','live','both') NOT NULL DEFAULT 'both',
  `description` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blocked_drivers`
--

CREATE TABLE `blocked_drivers` (
  `user_id` varchar(128) NOT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `blocked_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_messages`
--

CREATE TABLE `chat_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `group_name` varchar(64) NOT NULL,
  `user_id` varchar(128) NOT NULL,
  `text` text NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chat_messages`
--

INSERT INTO `chat_messages` (`id`, `group_name`, `user_id`, `text`, `created_at`) VALUES
(72, 'midway', '105861633310543857309', 'did the messages go away', '2026-05-08 20:13:23'),
(85, 'ohare', '105861633310543857309', 'hi', '2026-05-16 02:37:39'),
(86, 'ohare', '105861633310543857309', 'welcome to the group guys, I see a good number of downloads so far💜', '2026-05-19 19:22:43'),
(87, 'ohare', '105861633310543857309', 'there are more people with IOS iPhone, the sooner we can fully test this out the sooner ios version can be launched', '2026-05-19 19:23:24'),
(88, 'ohare', '109730046895318836784', 'guys let\'s the interactions alive here!', '2026-05-20 00:32:06'),
(89, 'ohare', '105861633310543857309', '👍', '2026-05-20 14:58:45'),
(90, 'ohare', '105861633310543857309', 'seems like there are not many android users', '2026-05-20 14:59:07'),
(91, 'ohare', '105861633310543857309', 'which I was expecting, pushing on the iPhone launch asap', '2026-05-20 14:59:27');

-- --------------------------------------------------------

--
-- Table structure for table `flight_data`
--

CREATE TABLE `flight_data` (
  `flight_id` varchar(64) NOT NULL,
  `airline` varchar(255) NOT NULL,
  `flight_number` varchar(50) NOT NULL,
  `destination` varchar(255) NOT NULL,
  `scheduled_time` varchar(32) NOT NULL,
  `status` varchar(100) NOT NULL,
  `gate` varchar(50) DEFAULT NULL,
  `airline_code` varchar(20) DEFAULT NULL,
  `is_arrival` tinyint(1) NOT NULL DEFAULT 0,
  `last_updated` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` varchar(128) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `type` varchar(100) DEFAULT 'general',
  `is_broadcast` tinyint(1) NOT NULL DEFAULT 0,
  `sent_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `body`, `data`, `type`, `is_broadcast`, `sent_at`) VALUES
(1, '104029414951343302193', 'New message in Midway Airport', 'Driver: g bhai', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"15\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"g bhai\",\"created_at\":\"2026-04-21T17:35:03Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:35:03'),
(2, '105861633310543857309', 'New message in Midway Airport', 'Driver: g bhai', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"15\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"g bhai\",\"created_at\":\"2026-04-21T17:35:03Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:35:03'),
(3, '103343709493359555007', 'New message in Ohare Airport', 'Driver: hi', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"16\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"hi\",\"created_at\":\"2026-04-21T17:46:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:46:00'),
(4, '104029414951343302193', 'New message in Ohare Airport', 'Driver: hi', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"16\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"hi\",\"created_at\":\"2026-04-21T17:46:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:46:00'),
(5, '103343709493359555007', 'New message in Ohare Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"17\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:46:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:46:09'),
(6, '104029414951343302193', 'New message in Ohare Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"17\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:46:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:46:09'),
(7, '103343709493359555007', 'New message in Ohare Airport', 'Driver: text', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"18\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"text\",\"created_at\":\"2026-04-21T17:46:10Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:46:10'),
(8, '104029414951343302193', 'New message in Ohare Airport', 'Driver: text', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"18\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"text\",\"created_at\":\"2026-04-21T17:46:10Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:46:10'),
(9, '105861633310543857309', 'New message in Ohare Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"19\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:17'),
(10, '103343709493359555007', 'New message in Ohare Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"19\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:17'),
(11, '104029414951343302193', 'New message in Ohare Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"19\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:17'),
(12, '112279872350852340529', 'New message in Ord-limo-lot Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"20\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:17'),
(13, '103343709493359555007', 'New message in Ord-limo-lot Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"20\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:17'),
(14, '104029414951343302193', 'New message in Ord-limo-lot Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"20\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:17'),
(15, '105861633310543857309', 'New message in Midway Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"21\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:22Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:22'),
(16, '103343709493359555007', 'New message in Midway Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"21\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:22Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:22'),
(17, '104029414951343302193', 'New message in Midway Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"21\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-04-21T17:47:22Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:22'),
(18, '112279872350852340529', 'New message in Ohare Airport', 'Driver: so I can delete msgs now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"22\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"so I can delete msgs now\",\"created_at\":\"2026-04-21T17:47:31Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:31'),
(19, '103343709493359555007', 'New message in Ohare Airport', 'Driver: so I can delete msgs now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"22\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"so I can delete msgs now\",\"created_at\":\"2026-04-21T17:47:31Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:31'),
(20, '104029414951343302193', 'New message in Ohare Airport', 'Driver: so I can delete msgs now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"22\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"so I can delete msgs now\",\"created_at\":\"2026-04-21T17:47:31Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:31'),
(21, '112279872350852340529', 'New message in Ohare Airport', 'Driver: like that', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"23\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"like that\",\"created_at\":\"2026-04-21T17:47:43Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:43'),
(22, '103343709493359555007', 'New message in Ohare Airport', 'Driver: like that', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"23\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"like that\",\"created_at\":\"2026-04-21T17:47:43Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:43'),
(23, '104029414951343302193', 'New message in Ohare Airport', 'Driver: like that', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"23\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"like that\",\"created_at\":\"2026-04-21T17:47:43Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:43'),
(24, '112279872350852340529', 'New message in Ohare Airport', 'Driver: did it delete', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"24\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"did it delete\",\"created_at\":\"2026-04-21T17:47:50Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:51'),
(25, '103343709493359555007', 'New message in Ohare Airport', 'Driver: did it delete', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"24\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"did it delete\",\"created_at\":\"2026-04-21T17:47:50Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:51'),
(26, '104029414951343302193', 'New message in Ohare Airport', 'Driver: did it delete', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"24\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"did it delete\",\"created_at\":\"2026-04-21T17:47:50Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:51'),
(27, '105861633310543857309', 'New message in Ohare Airport', 'Driver: which one', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"25\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"which one\",\"created_at\":\"2026-04-21T17:47:58Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:59'),
(28, '103343709493359555007', 'New message in Ohare Airport', 'Driver: which one', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"25\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"which one\",\"created_at\":\"2026-04-21T17:47:58Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:59'),
(29, '104029414951343302193', 'New message in Ohare Airport', 'Driver: which one', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"25\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"which one\",\"created_at\":\"2026-04-21T17:47:58Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:47:59'),
(30, '112279872350852340529', 'New message in Ohare Airport', 'Driver: your message', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"26\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"your message\",\"created_at\":\"2026-04-21T17:48:05Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:48:05'),
(31, '103343709493359555007', 'New message in Ohare Airport', 'Driver: your message', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"26\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"your message\",\"created_at\":\"2026-04-21T17:48:05Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:48:05'),
(32, '104029414951343302193', 'New message in Ohare Airport', 'Driver: your message', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"26\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"your message\",\"created_at\":\"2026-04-21T17:48:05Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:48:05'),
(33, '105861633310543857309', 'New message in Ohare Airport', 'Driver: nope I can still see it', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"27\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"nope I can still see it\",\"created_at\":\"2026-04-21T17:48:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:48:21'),
(34, '103343709493359555007', 'New message in Ohare Airport', 'Driver: nope I can still see it', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"27\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"nope I can still see it\",\"created_at\":\"2026-04-21T17:48:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:48:21'),
(35, '104029414951343302193', 'New message in Ohare Airport', 'Driver: nope I can still see it', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"27\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"nope I can still see it\",\"created_at\":\"2026-04-21T17:48:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:48:21'),
(36, '112279872350852340529', 'New message in Ohare Airport', 'Driver: now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"28\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now\",\"created_at\":\"2026-04-21T17:49:31Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:49:31'),
(37, '103343709493359555007', 'New message in Ohare Airport', 'Driver: now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"28\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now\",\"created_at\":\"2026-04-21T17:49:31Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:49:31'),
(38, '104029414951343302193', 'New message in Ohare Airport', 'Driver: now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"28\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now\",\"created_at\":\"2026-04-21T17:49:31Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:49:31'),
(39, '112279872350852340529', 'New message in Ohare Airport', 'Driver: now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"29\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now\",\"created_at\":\"2026-04-21T17:50:11Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:50:11'),
(40, '103343709493359555007', 'New message in Ohare Airport', 'Driver: now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"29\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now\",\"created_at\":\"2026-04-21T17:50:11Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:50:11'),
(41, '104029414951343302193', 'New message in Ohare Airport', 'Driver: now', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"29\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now\",\"created_at\":\"2026-04-21T17:50:11Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:50:11'),
(42, '105861633310543857309', 'New message in Ohare Airport', 'Driver: all your messages are deleted but mine are still t...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"30\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"all your messages are deleted but mine are still there\",\"created_at\":\"2026-04-21T17:50:39Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:50:39'),
(43, '103343709493359555007', 'New message in Ohare Airport', 'Driver: all your messages are deleted but mine are still t...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"30\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"all your messages are deleted but mine are still there\",\"created_at\":\"2026-04-21T17:50:39Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:50:39'),
(44, '104029414951343302193', 'New message in Ohare Airport', 'Driver: all your messages are deleted but mine are still t...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"30\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"all your messages are deleted but mine are still there\",\"created_at\":\"2026-04-21T17:50:39Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:50:39'),
(45, '105861633310543857309', 'New message in Ohare Airport', 'Driver: do you think it is because I\'m admin?', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"31\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"do you think it is because I\'m admin?\",\"created_at\":\"2026-04-21T17:51:01Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:01'),
(46, '103343709493359555007', 'New message in Ohare Airport', 'Driver: do you think it is because I\'m admin?', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"31\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"do you think it is because I\'m admin?\",\"created_at\":\"2026-04-21T17:51:01Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:01'),
(47, '104029414951343302193', 'New message in Ohare Airport', 'Driver: do you think it is because I\'m admin?', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"31\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"do you think it is because I\'m admin?\",\"created_at\":\"2026-04-21T17:51:01Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:01'),
(48, '112279872350852340529', 'New message in Ohare Airport', 'Driver: ur probly not', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"32\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ur probly not\",\"created_at\":\"2026-04-21T17:51:18Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:18'),
(49, '103343709493359555007', 'New message in Ohare Airport', 'Driver: ur probly not', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"32\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ur probly not\",\"created_at\":\"2026-04-21T17:51:18Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:18'),
(50, '104029414951343302193', 'New message in Ohare Airport', 'Driver: ur probly not', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"32\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ur probly not\",\"created_at\":\"2026-04-21T17:51:18Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:18'),
(51, '112279872350852340529', 'New message in Ohare Airport', 'Driver: are you', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"33\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"are you\",\"created_at\":\"2026-04-21T17:51:20Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:20'),
(52, '103343709493359555007', 'New message in Ohare Airport', 'Driver: are you', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"33\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"are you\",\"created_at\":\"2026-04-21T17:51:20Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:20'),
(53, '104029414951343302193', 'New message in Ohare Airport', 'Driver: are you', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"33\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"are you\",\"created_at\":\"2026-04-21T17:51:20Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:20'),
(54, '105861633310543857309', 'New message in Ohare Airport', 'Driver: you are right.. I\'m not admin', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"34\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"you are right.. I\'m not admin\",\"created_at\":\"2026-04-21T17:51:56Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:57'),
(55, '103343709493359555007', 'New message in Ohare Airport', 'Driver: you are right.. I\'m not admin', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"34\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"you are right.. I\'m not admin\",\"created_at\":\"2026-04-21T17:51:56Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:57'),
(56, '104029414951343302193', 'New message in Ohare Airport', 'Driver: you are right.. I\'m not admin', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"34\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"you are right.. I\'m not admin\",\"created_at\":\"2026-04-21T17:51:56Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:51:57'),
(57, '112279872350852340529', 'New message in Ohare Airport', 'Driver: yes my own msgs get deleted only not yours', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"35\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes my own msgs get deleted only not yours\",\"created_at\":\"2026-04-21T17:53:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:00'),
(58, '103343709493359555007', 'New message in Ohare Airport', 'Driver: yes my own msgs get deleted only not yours', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"35\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes my own msgs get deleted only not yours\",\"created_at\":\"2026-04-21T17:53:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:00'),
(59, '104029414951343302193', 'New message in Ohare Airport', 'Driver: yes my own msgs get deleted only not yours', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"35\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes my own msgs get deleted only not yours\",\"created_at\":\"2026-04-21T17:53:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:00'),
(60, '105861633310543857309', 'New message in Ohare Airport', 'Driver: yes', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"36\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"yes\",\"created_at\":\"2026-04-21T17:53:17Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:17'),
(61, '103343709493359555007', 'New message in Ohare Airport', 'Driver: yes', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"36\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"yes\",\"created_at\":\"2026-04-21T17:53:17Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:17'),
(62, '104029414951343302193', 'New message in Ohare Airport', 'Driver: yes', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"36\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"yes\",\"created_at\":\"2026-04-21T17:53:17Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:17'),
(63, '112279872350852340529', 'New message in Ohare Airport', 'Driver: ok will get this fixed', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"37\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ok will get this fixed\",\"created_at\":\"2026-04-21T17:53:32Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:33'),
(64, '103343709493359555007', 'New message in Ohare Airport', 'Driver: ok will get this fixed', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"37\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ok will get this fixed\",\"created_at\":\"2026-04-21T17:53:32Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:33'),
(65, '104029414951343302193', 'New message in Ohare Airport', 'Driver: ok will get this fixed', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"37\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ok will get this fixed\",\"created_at\":\"2026-04-21T17:53:32Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:53:33'),
(66, '112279872350852340529', 'New message in Ohare Airport', 'Driver: sure', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"38\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"sure\",\"created_at\":\"2026-04-21T17:54:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:54:28'),
(67, '105861633310543857309', 'New message in Ohare Airport', 'Driver: sure', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"38\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"sure\",\"created_at\":\"2026-04-21T17:54:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:54:28'),
(68, '104029414951343302193', 'New message in Ohare Airport', 'Driver: sure', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"38\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"sure\",\"created_at\":\"2026-04-21T17:54:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:54:28'),
(69, '105861633310543857309', 'New message in Ohare Airport', 'Driver: also when I type I\'m instead of i am it is changin...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"39\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"also when I type I\'m instead of i am it is changing the value of \'\",\"created_at\":\"2026-04-21T17:55:04Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:04'),
(70, '103343709493359555007', 'New message in Ohare Airport', 'Driver: also when I type I\'m instead of i am it is changin...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"39\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"also when I type I\'m instead of i am it is changing the value of \'\",\"created_at\":\"2026-04-21T17:55:04Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:04'),
(71, '104029414951343302193', 'New message in Ohare Airport', 'Driver: also when I type I\'m instead of i am it is changin...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"39\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"also when I type I\'m instead of i am it is changing the value of \'\",\"created_at\":\"2026-04-21T17:55:04Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:04'),
(72, '105861633310543857309', 'New message in Ohare Airport', 'Driver: it is changing the \'', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"40\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"it is changing the \'\",\"created_at\":\"2026-04-21T17:55:17Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:17'),
(73, '103343709493359555007', 'New message in Ohare Airport', 'Driver: it is changing the \'', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"40\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"it is changing the \'\",\"created_at\":\"2026-04-21T17:55:17Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:17'),
(74, '104029414951343302193', 'New message in Ohare Airport', 'Driver: it is changing the \'', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"40\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"it is changing the \'\",\"created_at\":\"2026-04-21T17:55:17Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:17'),
(75, '105861633310543857309', 'New message in Ohare Airport', 'Driver: I think there is also a limit of characters we can...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"41\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"I think there is also a limit of characters we can type i just noticed\",\"created_at\":\"2026-04-21T17:55:42Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:42'),
(76, '103343709493359555007', 'New message in Ohare Airport', 'Driver: I think there is also a limit of characters we can...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"41\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"I think there is also a limit of characters we can type i just noticed\",\"created_at\":\"2026-04-21T17:55:42Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:42'),
(77, '104029414951343302193', 'New message in Ohare Airport', 'Driver: I think there is also a limit of characters we can...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"41\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"I think there is also a limit of characters we can type i just noticed\",\"created_at\":\"2026-04-21T17:55:42Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:42'),
(78, '105861633310543857309', 'New message in Ohare Airport', 'Driver: can type. I just noticed', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"42\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"can type. I just noticed\",\"created_at\":\"2026-04-21T17:55:50Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:50'),
(79, '103343709493359555007', 'New message in Ohare Airport', 'Driver: can type. I just noticed', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"42\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"can type. I just noticed\",\"created_at\":\"2026-04-21T17:55:50Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:50'),
(80, '104029414951343302193', 'New message in Ohare Airport', 'Driver: can type. I just noticed', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"42\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"can type. I just noticed\",\"created_at\":\"2026-04-21T17:55:50Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:55:50'),
(81, '112279872350852340529', 'New message in Ohare Airport', 'Driver: &#038484+!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"43\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"&#038484+!\",\"created_at\":\"2026-04-21T17:57:03Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:57:04'),
(82, '105861633310543857309', 'New message in Ohare Airport', 'Driver: &#038484+!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"43\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"&#038484+!\",\"created_at\":\"2026-04-21T17:57:03Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:57:04'),
(83, '104029414951343302193', 'New message in Ohare Airport', 'Driver: &#038484+!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"43\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"&#038484+!\",\"created_at\":\"2026-04-21T17:57:03Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:57:04'),
(84, '112279872350852340529', 'New message in Ohare Airport', 'Driver: main samjh nhi. limit characters?', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"44\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"main samjh nhi. limit characters?\",\"created_at\":\"2026-04-21T17:57:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:57:16'),
(85, '105861633310543857309', 'New message in Ohare Airport', 'Driver: main samjh nhi. limit characters?', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"44\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"main samjh nhi. limit characters?\",\"created_at\":\"2026-04-21T17:57:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:57:16'),
(86, '104029414951343302193', 'New message in Ohare Airport', 'Driver: main samjh nhi. limit characters?', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"44\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"main samjh nhi. limit characters?\",\"created_at\":\"2026-04-21T17:57:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:57:16'),
(87, '112279872350852340529', 'New message in Ohare Airport', 'Driver: @wafi what do you mean', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"45\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"@wafi what do you mean\",\"created_at\":\"2026-04-21T17:59:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:01'),
(88, '103343709493359555007', 'New message in Ohare Airport', 'Driver: @wafi what do you mean', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"45\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"@wafi what do you mean\",\"created_at\":\"2026-04-21T17:59:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:01'),
(89, '104029414951343302193', 'New message in Ohare Airport', 'Driver: @wafi what do you mean', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"45\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"@wafi what do you mean\",\"created_at\":\"2026-04-21T17:59:00Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:01'),
(90, '105861633310543857309', 'New message in Ohare Airport', 'Driver: like limit hai kite words type ker skte hain', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"46\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"like limit hai kite words type ker skte hain\",\"created_at\":\"2026-04-21T17:59:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:17'),
(91, '103343709493359555007', 'New message in Ohare Airport', 'Driver: like limit hai kite words type ker skte hain', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"46\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"like limit hai kite words type ker skte hain\",\"created_at\":\"2026-04-21T17:59:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:17'),
(92, '104029414951343302193', 'New message in Ohare Airport', 'Driver: like limit hai kite words type ker skte hain', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"46\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"like limit hai kite words type ker skte hain\",\"created_at\":\"2026-04-21T17:59:16Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:17'),
(93, '112279872350852340529', 'New message in Ohare Airport', 'Driver: kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk 12345', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"47\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk 12345\",\"created_at\":\"2026-04-21T17:59:51Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:51'),
(94, '103343709493359555007', 'New message in Ohare Airport', 'Driver: kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk 12345', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"47\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk 12345\",\"created_at\":\"2026-04-21T17:59:51Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:51'),
(95, '104029414951343302193', 'New message in Ohare Airport', 'Driver: kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk 12345', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"47\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk kkkkkkkkkk 12345\",\"created_at\":\"2026-04-21T17:59:51Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 17:59:51'),
(96, '112279872350852340529', 'New message in Ohare Airport', 'Driver: yes that\'s the limit 👆', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"48\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes that\'s the limit \\ud83d\\udc46\",\"created_at\":\"2026-04-21T18:00:25Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:25'),
(97, '103343709493359555007', 'New message in Ohare Airport', 'Driver: yes that\'s the limit 👆', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"48\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes that\'s the limit \\ud83d\\udc46\",\"created_at\":\"2026-04-21T18:00:25Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:25'),
(98, '104029414951343302193', 'New message in Ohare Airport', 'Driver: yes that\'s the limit 👆', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"48\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes that\'s the limit \\ud83d\\udc46\",\"created_at\":\"2026-04-21T18:00:25Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:25'),
(99, '105861633310543857309', 'New message in Ohare Airport', 'Driver: 12345678910111213141516171819202122232425', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"49\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"12345678910111213141516171819202122232425\",\"created_at\":\"2026-04-21T18:00:29Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:29'),
(100, '103343709493359555007', 'New message in Ohare Airport', 'Driver: 12345678910111213141516171819202122232425', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"49\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"12345678910111213141516171819202122232425\",\"created_at\":\"2026-04-21T18:00:29Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:29'),
(101, '104029414951343302193', 'New message in Ohare Airport', 'Driver: 12345678910111213141516171819202122232425', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"49\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"12345678910111213141516171819202122232425\",\"created_at\":\"2026-04-21T18:00:29Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:29'),
(102, '112279872350852340529', 'New message in Ohare Airport', 'Driver: bhai voice msg krain samjh nhi ae bat ap ki', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"50\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"bhai voice msg krain samjh nhi ae bat ap ki\",\"created_at\":\"2026-04-21T18:00:49Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:49'),
(103, '105861633310543857309', 'New message in Ohare Airport', 'Driver: bhai voice msg krain samjh nhi ae bat ap ki', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"50\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"bhai voice msg krain samjh nhi ae bat ap ki\",\"created_at\":\"2026-04-21T18:00:49Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:49'),
(104, '104029414951343302193', 'New message in Ohare Airport', 'Driver: bhai voice msg krain samjh nhi ae bat ap ki', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"50\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"bhai voice msg krain samjh nhi ae bat ap ki\",\"created_at\":\"2026-04-21T18:00:49Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:49'),
(105, '105861633310543857309', 'New message in Ohare Airport', 'Driver: I did it till 25 but it cut off at 21', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"51\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"I did it till 25 but it cut off at 21\",\"created_at\":\"2026-04-21T18:00:56Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:56'),
(106, '103343709493359555007', 'New message in Ohare Airport', 'Driver: I did it till 25 but it cut off at 21', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"51\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"I did it till 25 but it cut off at 21\",\"created_at\":\"2026-04-21T18:00:56Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:56'),
(107, '104029414951343302193', 'New message in Ohare Airport', 'Driver: I did it till 25 but it cut off at 21', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"51\",\"sender_id\":\"112279872350852340529\",\"sender_name\":\"Driver\",\"message_text\":\"I did it till 25 but it cut off at 21\",\"created_at\":\"2026-04-21T18:00:56Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:00:56'),
(108, '112279872350852340529', 'New message in Ohare Airport', 'Driver: ok I will send you voice @irfan', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"52\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ok I will send you voice @irfan\",\"created_at\":\"2026-04-21T18:01:22Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:01:22'),
(109, '103343709493359555007', 'New message in Ohare Airport', 'Driver: ok I will send you voice @irfan', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"52\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ok I will send you voice @irfan\",\"created_at\":\"2026-04-21T18:01:22Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:01:22'),
(110, '104029414951343302193', 'New message in Ohare Airport', 'Driver: ok I will send you voice @irfan', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"52\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"ok I will send you voice @irfan\",\"created_at\":\"2026-04-21T18:01:22Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-21 18:01:22'),
(111, '112279872350852340529', 'New message in Ohare Airport', 'Driver: hshsue hsisiie. ushsuiie hishejeiie eiebuisiejebbe...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"53\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"hshsue hsisiie. ushsuiie hishejeiie eiebuisiejebbejeieobeb jjwiebje jbwhevhwisb sbsisbbeheis. jisjejeie. jehejjeieb juijjjjjjjjebeb. heje\",\"created_at\":\"2026-04-22T06:30:05Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-22 06:30:05'),
(112, '105861633310543857309', 'New message in Ohare Airport', 'Driver: hshsue hsisiie. ushsuiie hishejeiie eiebuisiejebbe...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"53\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"hshsue hsisiie. ushsuiie hishejeiie eiebuisiejebbejeieobeb jjwiebje jbwhevhwisb sbsisbbeheis. jisjejeie. jehejjeieb juijjjjjjjjebeb. heje\",\"created_at\":\"2026-04-22T06:30:05Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-22 06:30:05'),
(113, '104029414951343302193', 'New message in Ohare Airport', 'Driver: hshsue hsisiie. ushsuiie hishejeiie eiebuisiejebbe...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"53\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"hshsue hsisiie. ushsuiie hishejeiie eiebuisiejebbejeieobeb jjwiebje jbwhevhwisb sbsisbbeheis. jisjejeie. jehejjeieb juijjjjjjjjebeb. heje\",\"created_at\":\"2026-04-22T06:30:05Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-22 06:30:05'),
(114, '112279872350852340529', 'New message in Ohare Airport', 'Driver: 12345678910 12345678910 12345678910', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"54\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"12345678910 12345678910 12345678910\",\"created_at\":\"2026-04-22T06:30:52Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-22 06:30:52'),
(115, '105861633310543857309', 'New message in Ohare Airport', 'Driver: 12345678910 12345678910 12345678910', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"54\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"12345678910 12345678910 12345678910\",\"created_at\":\"2026-04-22T06:30:52Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-22 06:30:52'),
(116, '104029414951343302193', 'New message in Ohare Airport', 'Driver: 12345678910 12345678910 12345678910', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"54\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"12345678910 12345678910 12345678910\",\"created_at\":\"2026-04-22T06:30:52Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-04-22 06:30:52'),
(117, '105861633310543857309', 'New message in Midway Airport', 'Driver: hello', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"63\",\"sender_id\":\"105865704666233192998\",\"sender_name\":\"Driver\",\"message_text\":\"hello\",\"created_at\":\"2026-05-08T19:59:51Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 19:59:51'),
(118, '105861633310543857309', 'New message in Midway Airport', 'Driver: checking', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"64\",\"sender_id\":\"105865704666233192998\",\"sender_name\":\"Driver\",\"message_text\":\"checking\",\"created_at\":\"2026-05-08T19:59:53Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 19:59:53'),
(119, '105861633310543857309', 'New message in Ohare Airport', 'Driver: hello check 123', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"65\",\"sender_id\":\"105865704666233192998\",\"sender_name\":\"Driver\",\"message_text\":\"hello check 123\",\"created_at\":\"2026-05-08T20:00:02Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:00:02'),
(120, '105865704666233192998', 'New message in Midway Airport', 'Driver: hi', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"66\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"hi\",\"created_at\":\"2026-05-08T20:00:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:00:08'),
(121, '105861633310543857309', 'New message in Ord-limo-lot Airport', 'Driver: hello limo check 1 2', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"68\",\"sender_id\":\"105865704666233192998\",\"sender_name\":\"Driver\",\"message_text\":\"hello limo check 1 2\",\"created_at\":\"2026-05-08T20:00:09Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:00:09'),
(122, '105865704666233192998', 'New message in Midway Airport', 'Driver: got it', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"67\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"got it\",\"created_at\":\"2026-05-08T20:00:09Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:00:09'),
(123, '105865704666233192998', 'New message in Midway Airport', 'Driver: now I\'m gonna try deleting to test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"69\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"now I\'m gonna try deleting to test\",\"created_at\":\"2026-05-08T20:00:26Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:00:27'),
(124, '105861633310543857309', 'New message in Midway Airport', 'Driver: ok', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"70\",\"sender_id\":\"105865704666233192998\",\"sender_name\":\"Driver\",\"message_text\":\"ok\",\"created_at\":\"2026-05-08T20:01:42Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:01:42'),
(125, '105865704666233192998', 'New message in Midway Airport', 'Driver: I\'m', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"71\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"I\'m\",\"created_at\":\"2026-05-08T20:05:23Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:05:23'),
(126, '105865704666233192998', 'New message in Midway Airport', 'Driver: did the messages go away', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"72\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"did the messages go away\",\"created_at\":\"2026-05-08T20:13:23Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:13:23'),
(127, '105865704666233192998', 'New message in Midway Airport', 'Driver: on all chats', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"73\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"on all chats\",\"created_at\":\"2026-05-08T20:13:28Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-08 20:13:29');
INSERT INTO `notifications` (`id`, `user_id`, `title`, `body`, `data`, `type`, `is_broadcast`, `sent_at`) VALUES
(128, '105861633310543857309', 'New message in Midway Airport', 'Driver: hello', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"74\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"hello\",\"created_at\":\"2026-05-11T16:25:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 16:25:21'),
(129, '103343709493359555007', 'New message in Midway Airport', 'Driver: yes sir', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"75\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"yes sir\",\"created_at\":\"2026-05-11T16:25:41Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 16:25:41'),
(130, '105861633310543857309', 'New message in Midway Airport', 'Driver: I am', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"76\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"I am\",\"created_at\":\"2026-05-11T16:29:37Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 16:29:37'),
(131, '105861633310543857309', 'New message in Ord-limo-lot Airport', 'Driver: I\'m', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"77\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"I\'m\",\"created_at\":\"2026-05-11T16:29:58Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 16:29:59'),
(132, '105861633310543857309', 'New message in Midway Airport', 'Driver: I\'m', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"78\",\"sender_id\":\"103343709493359555007\",\"sender_name\":\"Driver\",\"message_text\":\"I\'m\",\"created_at\":\"2026-05-11T16:50:13Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 16:50:14'),
(133, '112909289478185563271', 'New message in Ohare Airport', 'Driver: chekcing', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"79\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"chekcing\",\"created_at\":\"2026-05-11T17:05:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:05:08'),
(134, '103343709493359555007', 'New message in Ohare Airport', 'Driver: chekcing', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"79\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"chekcing\",\"created_at\":\"2026-05-11T17:05:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:05:08'),
(135, '112909289478185563271', 'New message in Ohare Airport', 'Driver: testing', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"80\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"testing\",\"created_at\":\"2026-05-11T17:05:11Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:05:12'),
(136, '103343709493359555007', 'New message in Ohare Airport', 'Driver: testing', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"80\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"testing\",\"created_at\":\"2026-05-11T17:05:11Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:05:12'),
(137, '112909289478185563271', 'New message in Midway Airport', 'Driver: vteating', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"81\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"vteating\",\"created_at\":\"2026-05-11T17:07:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:09'),
(138, '103343709493359555007', 'New message in Midway Airport', 'Driver: vteating', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"81\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"vteating\",\"created_at\":\"2026-05-11T17:07:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:09'),
(139, '105861633310543857309', 'New message in Midway Airport', 'Driver: vteating', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"81\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"vteating\",\"created_at\":\"2026-05-11T17:07:08Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:09'),
(140, '112909289478185563271', 'New message in Midway Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"82\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-05-11T17:07:12Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:12'),
(141, '103343709493359555007', 'New message in Midway Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"82\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-05-11T17:07:12Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:12'),
(142, '105861633310543857309', 'New message in Midway Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"midway\",\"message_id\":\"82\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-05-11T17:07:12Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:12'),
(143, '112909289478185563271', 'New message in Ohare Airport', 'Driver: rtest', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"83\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"rtest\",\"created_at\":\"2026-05-11T17:07:19Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:19'),
(144, '103343709493359555007', 'New message in Ohare Airport', 'Driver: rtest', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"83\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"rtest\",\"created_at\":\"2026-05-11T17:07:19Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:19'),
(145, '105861633310543857309', 'New message in Ohare Airport', 'Driver: rtest', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"83\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"rtest\",\"created_at\":\"2026-05-11T17:07:19Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:19'),
(146, '112909289478185563271', 'New message in Ord-limo-lot Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"84\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-05-11T17:07:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:21'),
(147, '103343709493359555007', 'New message in Ord-limo-lot Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"84\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-05-11T17:07:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:21'),
(148, '105861633310543857309', 'New message in Ord-limo-lot Airport', 'Driver: test', '{\"type\":\"chat_message\",\"group\":\"ord-limo-lot\",\"message_id\":\"84\",\"sender_id\":\"104029414951343302193\",\"sender_name\":\"Driver\",\"message_text\":\"test\",\"created_at\":\"2026-05-11T17:07:21Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-11 17:07:21'),
(149, '109730046895318836784', 'New message in Ohare Airport', 'Driver: welcome to the group guys, I see a good number of ...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"86\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"welcome to the group guys, I see a good number of downloads so far\\ud83d\\udc9c\",\"created_at\":\"2026-05-19T19:22:43Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-19 19:22:43'),
(150, '113318565069829518654', 'New message in Ohare Airport', 'Driver: welcome to the group guys, I see a good number of ...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"86\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"welcome to the group guys, I see a good number of downloads so far\\ud83d\\udc9c\",\"created_at\":\"2026-05-19T19:22:43Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-19 19:22:43'),
(151, '101882812353949771790', 'New message in Ohare Airport', 'Driver: welcome to the group guys, I see a good number of ...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"86\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"welcome to the group guys, I see a good number of downloads so far\\ud83d\\udc9c\",\"created_at\":\"2026-05-19T19:22:43Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-19 19:22:43'),
(152, '109730046895318836784', 'New message in Ohare Airport', 'Driver: there are more people with IOS iPhone, the sooner ...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"87\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"there are more people with IOS iPhone, the sooner we can fully test this out the sooner ios version can be launched\",\"created_at\":\"2026-05-19T19:23:24Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-19 19:23:25'),
(153, '113318565069829518654', 'New message in Ohare Airport', 'Driver: there are more people with IOS iPhone, the sooner ...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"87\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"there are more people with IOS iPhone, the sooner we can fully test this out the sooner ios version can be launched\",\"created_at\":\"2026-05-19T19:23:24Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-19 19:23:25'),
(154, '101882812353949771790', 'New message in Ohare Airport', 'Driver: there are more people with IOS iPhone, the sooner ...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"87\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"there are more people with IOS iPhone, the sooner we can fully test this out the sooner ios version can be launched\",\"created_at\":\"2026-05-19T19:23:24Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-19 19:23:25'),
(155, '106003247170311016658', 'New message in Ohare Airport', 'Driver: guys let\'s the interactions alive here!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"88\",\"sender_id\":\"109730046895318836784\",\"sender_name\":\"Driver\",\"message_text\":\"guys let\'s the interactions alive here!\",\"created_at\":\"2026-05-20T00:32:06Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 00:32:06'),
(156, '105861633310543857309', 'New message in Ohare Airport', 'Driver: guys let\'s the interactions alive here!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"88\",\"sender_id\":\"109730046895318836784\",\"sender_name\":\"Driver\",\"message_text\":\"guys let\'s the interactions alive here!\",\"created_at\":\"2026-05-20T00:32:06Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 00:32:06'),
(157, '113318565069829518654', 'New message in Ohare Airport', 'Driver: guys let\'s the interactions alive here!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"88\",\"sender_id\":\"109730046895318836784\",\"sender_name\":\"Driver\",\"message_text\":\"guys let\'s the interactions alive here!\",\"created_at\":\"2026-05-20T00:32:06Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 00:32:06'),
(158, '101882812353949771790', 'New message in Ohare Airport', 'Driver: guys let\'s the interactions alive here!', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"88\",\"sender_id\":\"109730046895318836784\",\"sender_name\":\"Driver\",\"message_text\":\"guys let\'s the interactions alive here!\",\"created_at\":\"2026-05-20T00:32:06Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 00:32:06'),
(159, '106003247170311016658', 'New message in Ohare Airport', 'Driver: 👍', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"89\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"\\ud83d\\udc4d\",\"created_at\":\"2026-05-20T14:58:45Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:58:45'),
(160, '109730046895318836784', 'New message in Ohare Airport', 'Driver: 👍', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"89\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"\\ud83d\\udc4d\",\"created_at\":\"2026-05-20T14:58:45Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:58:45'),
(161, '113318565069829518654', 'New message in Ohare Airport', 'Driver: 👍', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"89\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"\\ud83d\\udc4d\",\"created_at\":\"2026-05-20T14:58:45Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:58:45'),
(162, '101882812353949771790', 'New message in Ohare Airport', 'Driver: 👍', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"89\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"\\ud83d\\udc4d\",\"created_at\":\"2026-05-20T14:58:45Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:58:45'),
(163, '106003247170311016658', 'New message in Ohare Airport', 'Driver: seems like there are not many android users', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"90\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"seems like there are not many android users\",\"created_at\":\"2026-05-20T14:59:07Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:08'),
(164, '109730046895318836784', 'New message in Ohare Airport', 'Driver: seems like there are not many android users', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"90\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"seems like there are not many android users\",\"created_at\":\"2026-05-20T14:59:07Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:08'),
(165, '113318565069829518654', 'New message in Ohare Airport', 'Driver: seems like there are not many android users', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"90\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"seems like there are not many android users\",\"created_at\":\"2026-05-20T14:59:07Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:08'),
(166, '101882812353949771790', 'New message in Ohare Airport', 'Driver: seems like there are not many android users', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"90\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"seems like there are not many android users\",\"created_at\":\"2026-05-20T14:59:07Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:08'),
(167, '106003247170311016658', 'New message in Ohare Airport', 'Driver: which I was expecting, pushing on the iPhone launc...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"91\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"which I was expecting, pushing on the iPhone launch asap\",\"created_at\":\"2026-05-20T14:59:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:27'),
(168, '109730046895318836784', 'New message in Ohare Airport', 'Driver: which I was expecting, pushing on the iPhone launc...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"91\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"which I was expecting, pushing on the iPhone launch asap\",\"created_at\":\"2026-05-20T14:59:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:27'),
(169, '113318565069829518654', 'New message in Ohare Airport', 'Driver: which I was expecting, pushing on the iPhone launc...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"91\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"which I was expecting, pushing on the iPhone launch asap\",\"created_at\":\"2026-05-20T14:59:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:27'),
(170, '101882812353949771790', 'New message in Ohare Airport', 'Driver: which I was expecting, pushing on the iPhone launc...', '{\"type\":\"chat_message\",\"group\":\"ohare\",\"message_id\":\"91\",\"sender_id\":\"105861633310543857309\",\"sender_name\":\"Driver\",\"message_text\":\"which I was expecting, pushing on the iPhone launch asap\",\"created_at\":\"2026-05-20T14:59:27Z\",\"action\":\"open_chat\"}', 'chat_message', 0, '2026-05-20 14:59:27');

-- --------------------------------------------------------

--
-- Table structure for table `parking_lots`
--

CREATE TABLE `parking_lots` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `radius_meters` int(11) NOT NULL DEFAULT 500,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `parking_lots`
--

INSERT INTO `parking_lots` (`id`, `name`, `latitude`, `longitude`, `radius_meters`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'MidwayLot', 41.7867750, -87.7521880, 1000, 1, '2026-04-20 05:10:49', '2026-05-06 01:48:05'),
(2, 'OhareAlphaLot', 41.9774400, -87.8770400, 1000, 1, '2026-04-20 05:10:49', '2026-04-23 02:17:16'),
(3, 'OhareDeltaLot', 41.9655760, -87.8813700, 1000, 1, '2026-04-20 05:10:49', '2026-04-23 02:16:56'),
(5, 'MidwayLot-Pro', 41.7867750, -87.7521880, 600, 1, '2026-04-20 05:10:49', '2026-04-20 05:10:49'),
(6, 'OhareDeltaLot-Prod', 41.9741620, -87.9073210, 700, 1, '2026-04-20 05:10:49', '2026-04-20 05:10:49'),
(7, 'OhareAlphaLot-Prod', 41.9802640, -87.9086070, 700, 1, '2026-04-20 05:10:49', '2026-04-20 05:10:49'),
(8, 'ORD Limo Lot', 41.9979930, -87.8865600, 1000, 1, '2026-04-20 05:10:49', '2026-04-21 05:45:44');

-- --------------------------------------------------------

--
-- Table structure for table `price_alerts`
--

CREATE TABLE `price_alerts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` varchar(128) NOT NULL,
  `pickup` varchar(255) NOT NULL,
  `dropoff` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `price_alerts`
--

INSERT INTO `price_alerts` (`id`, `user_id`, `pickup`, `dropoff`, `price`, `created_at`, `updated_at`) VALUES
(12, '105861633310543857309', 'OhareAlphaLot', 'downtown', 14.00, '2026-05-11 17:05:46', '2026-05-11 17:05:46'),
(13, '105861633310543857309', 'OhareAlphaLot', 'yuhhuujj', 33.00, '2026-05-16 02:36:55', '2026-05-16 02:36:55'),
(14, '105861633310543857309', 'OhareAlphaLot', 'downtown', 20.00, '2026-05-19 18:50:01', '2026-05-19 18:50:01'),
(15, '109730046895318836784', 'OhareAlphaLot', 'Waukegan', 30.00, '2026-05-19 22:27:51', '2026-05-19 22:27:51'),
(16, '109730046895318836784', 'OhareAlphaLot', 'Downtown', 27.00, '2026-05-19 22:46:47', '2026-05-19 22:46:47');

-- --------------------------------------------------------

--
-- Table structure for table `price_alert_likes`
--

CREATE TABLE `price_alert_likes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `alert_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` varchar(128) NOT NULL,
  `type` enum('like','dislike') NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `price_alert_likes`
--

INSERT INTO `price_alert_likes` (`id`, `alert_id`, `user_id`, `type`, `created_at`) VALUES
(16, 12, '112909289478185563271', 'dislike', '2026-05-11 17:13:12'),
(18, 13, '105861633310543857309', 'dislike', '2026-05-16 02:37:16'),
(19, 14, '105861633310543857309', 'dislike', '2026-05-19 18:50:05'),
(20, 16, '106003247170311016658', 'dislike', '2026-05-20 00:23:40'),
(21, 15, '106003247170311016658', 'dislike', '2026-05-20 00:23:44'),
(22, 15, '105861633310543857309', 'like', '2026-05-20 01:06:28'),
(23, 16, '105861633310543857309', 'like', '2026-05-20 01:06:32');

-- --------------------------------------------------------

--
-- Table structure for table `suggestions`
--

CREATE TABLE `suggestions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` varchar(128) NOT NULL,
  `driver_name` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `status` enum('pending','reviewed','implemented') NOT NULL DEFAULT 'pending',
  `admin_response` text DEFAULT NULL,
  `responded_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `suggestions`
--

INSERT INTO `suggestions` (`id`, `user_id`, `driver_name`, `title`, `description`, `status`, `admin_response`, `responded_at`, `created_at`) VALUES
(2, '112909289478185563271', 'Unknown Driver', 'hello', 'hello sir how are you', 'pending', NULL, NULL, '2026-04-21 11:09:33'),
(3, '104029414951343302193', 'Driver Grid', 'testt', 'testt\nhshshshshsh hshshshs hshshshsh', 'pending', NULL, NULL, '2026-05-12 23:39:03'),
(4, '104029414951343302193', 'Driver Grid', 'hsshhahshsshs', 'ueeueueueueueueuueurueueueuue', 'pending', NULL, NULL, '2026-05-12 23:39:53'),
(5, '112279872350852340529', 'Wafi Habib', 'test suggestion', 'testing suggestion box', 'pending', NULL, NULL, '2026-05-13 00:34:04');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` varchar(128) NOT NULL,
  `email` varchar(255) NOT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `photo_url` text DEFAULT NULL,
  `fcm_token` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `location_updated_at` datetime DEFAULT NULL,
  `last_sign_in` datetime DEFAULT current_timestamp(),
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `email`, `display_name`, `photo_url`, `fcm_token`, `latitude`, `longitude`, `location_updated_at`, `last_sign_in`, `created_at`, `updated_at`) VALUES
('101882812353949771790', 'mr.omarhaq@gmail.com', 'Omar Haq', 'https://lh3.googleusercontent.com/a/ACg8ocJ9KtKYT7FFnus9rqeDXdUq7Bkqym8v_TNlo-TalIgw2wUuIfhbdw=s96-c', 'cmm-oEiqTOykkM8C76nzFZ:APA91bFr2eD3eBUBnHt_PCPrN4LtVJe54XbWcCi4mrNIjvXZEi96Z1d9eLQkj-LjwkiqnYJlOuw1OxZZasSvKvZsALwabvKik5TZLsVj_bvVXX632fwIm38', 41.7589244, -88.0433370, '2026-05-20 14:59:41', '2026-05-19 18:17:23', '2026-05-19 18:17:23', '2026-05-20 14:59:41'),
('103343709493359555007', 'irfan.200818@gmail.com', 'irfan ali soomro', 'https://lh3.googleusercontent.com/a/ACg8ocKN4lpmu-_fGq2imcZF6noCP7T5xmOfzv-bk_2wt11pI6nfeNka=s96-c', 'cpBhqac3QgeYoXwaSbSjvZ:APA91bFGKABYEWbh0WP2CabUwK0_YJWHcrkVKzO0iuG5qla6HzoqDpcUG_k2Er8DKhQ2tNcyqyJ_B_Q-d3B0hzwn1DPxJc-RE3EbG5GeqFxILYuJW3eaJCg', 24.8019170, 67.0297205, '2026-05-06 09:15:12', '2026-05-13 00:07:40', '2026-04-20 05:12:11', '2026-05-13 00:07:45'),
('104029414951343302193', 'drivergridapp@gmail.com', 'Driver Grid', 'https://lh3.googleusercontent.com/a/ACg8ocL1Owa8vZ9t5VmllQyFhjL3JdvRAW8YZCmqBnp7sMNN2-3nKg=s96-c', 'eq-BDxS4R6yrU9Dn0YKVVZ:APA91bEmPr_RGYZrqNdBmklL_VYjT-LB_oaFoetqpEBAEyN9zwmmLyZ66t9ht1p83_zFGPSJbtDc7Kb0D5gVCoHLQEfFyFmdQK07pi3nhGb2UUMrQZnC0l8', 41.7492733, -88.2290800, '2026-05-14 06:45:40', '2026-05-13 20:13:52', '2026-04-21 15:56:27', '2026-05-14 06:45:40'),
('105861633310543857309', 'mohibhabib09@gmail.com', 'mohib habib', 'https://lh3.googleusercontent.com/a/ACg8ocL92pBddwlK9qImNA238B4sDvDbpkIRKkxU4zcEjEWyGOOeD3ckFQ=s96-c', 'eq-BDxS4R6yrU9Dn0YKVVZ:APA91bEmPr_RGYZrqNdBmklL_VYjT-LB_oaFoetqpEBAEyN9zwmmLyZ66t9ht1p83_zFGPSJbtDc7Kb0D5gVCoHLQEfFyFmdQK07pi3nhGb2UUMrQZnC0l8', 41.8668362, -87.6249067, '2026-05-20 16:39:50', '2026-05-19 18:29:50', '2026-04-21 15:52:44', '2026-05-20 16:39:50'),
('105865704666233192998', 'mwhab786@gmail.com', 'Mohammed H', 'https://lh3.googleusercontent.com/a/ACg8ocKMk0tvqYm46YCqfcwGlMSuEhUYB-A5vXaIaYpqNwq5BLfjxQ=s96-c', 'fkUIkePXRruamxraPCXRU4:APA91bFrf9bBBEgKO3YcYs5rltqhBSSRVQon18aKCVruFMjmx3KbDgeg4mkneGasc5MIAyiXDmkgJnqk5Uzi-EA8bzFd5DL_I1sYAmrRsOBlVqJO_ffgOQ8', NULL, NULL, NULL, '2026-05-08 19:59:29', '2026-05-08 19:59:29', '2026-05-08 19:59:31'),
('106003247170311016658', 'mohammedmujahed527@gmail.com', 'Mohammed Mujahed', 'https://lh3.googleusercontent.com/a/ACg8ocJIrJvKxpPQaYEeCSp9b1uU4oXRW7gY2Q48OKRQ0u3RzowD=s96-c', 'eUxR5eVSRdSxg4VMiE-fYq:APA91bFXiY5bVzy1veLHkOOAxjZQakD805017RhbYpSdVGPsKO09CsHPEkSQ6wLVSXX7s5bOOj8_qs1uITEaMHbtvI2T-nZ8s97myOg0d5TsYGBvr5TtVd4', 41.9774052, -87.8770828, '2026-05-20 04:39:09', '2026-05-19 19:30:10', '2026-05-19 19:30:10', '2026-05-20 04:39:09'),
('109730046895318836784', 'forwork3389@gmail.com', 'Business', 'https://lh3.googleusercontent.com/a/ACg8ocJE1kMC9gJoc47LRMPbuFI_JHEqsJ7aHCeGalJsnU18B6_UAIE=s96-c', 'dmDmc_DZS0C3Lqr-JdpVyP:APA91bHmm0PKaNVSH3Mjr3YcPSUu5R5JCgm91ojXKLTaI-3be4QTs4OxMCTd9t8rERQuqKsFWlORi4t-Aghrcyq8_rl0wvT6x7C22r1oYvk2lpi-jhiXtt4', 41.9745650, -87.8780394, '2026-05-20 01:16:18', '2026-05-19 18:17:48', '2026-05-19 18:17:48', '2026-05-20 01:16:18'),
('112279872350852340529', 'wafflien@gmail.com', 'Wafi Habib', 'https://lh3.googleusercontent.com/a/ACg8ocJM0jTYjmBibZ5XRj4cj-ZUh83VK5DAn72cpdh8vPDJkYufBrOQrA=s96-c', 'cGi3LgaaRSeCfr_1ytCo9E:APA91bGXrOXjawLh6wJj2-ASfhwP6aG21TNT4v6M31JodV93XwnA84tJnnCjHvtRFAkTspFeiNR_99lkSnJ5NcZK8qEbaZhBUJkJo-WjLCLSwFun-CRNwms', NULL, NULL, NULL, '2026-05-13 00:33:45', '2026-04-21 17:46:57', '2026-05-13 00:33:47'),
('112909289478185563271', 'invenzy@gmail.com', 'EZevon Store', 'https://lh3.googleusercontent.com/a/ACg8ocLFqUrOhf0lYcKisf8U6Oz1hYVTvVpcS69iZqSYb0mi93zE4rg=s96-c', 'cpBhqac3QgeYoXwaSbSjvZ:APA91bFGKABYEWbh0WP2CabUwK0_YJWHcrkVKzO0iuG5qla6HzoqDpcUG_k2Er8DKhQ2tNcyqyJ_B_Q-d3B0hzwn1DPxJc-RE3EbG5GeqFxILYuJW3eaJCg', NULL, NULL, NULL, '2026-05-11 17:01:40', '2026-04-20 18:06:24', '2026-05-11 17:01:44'),
('113318565069829518654', 'azhar.chicago82@gmail.com', 'Azhar Razak', 'https://lh3.googleusercontent.com/a/ACg8ocKuRO6tvXQR7hx2wZ48JgtRYy7GFVfKdtSpxqhUIOxuieWDSH4=s96-c', 'cLc6vAAOQa6yXCqZoKdUP_:APA91bECDqPYt248qYp_u2x3K1UvoB026psJa311Sla-y4Z_zQZON4alFLBf7mHI4p_acvigEHNeaLL69N6lAPCgZGeNQNT6G4FVXMo0VMNTSELIKJE8G4s', 42.0264789, -87.7016060, '2026-05-20 01:48:40', '2026-05-19 18:17:48', '2026-05-19 18:17:48', '2026-05-20 01:48:40');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `active_users`
--
ALTER TABLE `active_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_active_users_user_location` (`user_id`,`location_name`),
  ADD KEY `idx_active_users_location_status_last_seen` (`location_name`,`status`,`last_seen`),
  ADD KEY `idx_active_users_last_seen` (`last_seen`);

--
-- Indexes for table `admin_users`
--
ALTER TABLE `admin_users`
  ADD PRIMARY KEY (`user_id`);

--
-- Indexes for table `app_config`
--
ALTER TABLE `app_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_app_config_env_key` (`environment`,`config_key`),
  ADD KEY `idx_app_config_key_active` (`config_key`,`is_active`),
  ADD KEY `idx_app_config_environment_active` (`environment`,`is_active`);

--
-- Indexes for table `blocked_drivers`
--
ALTER TABLE `blocked_drivers`
  ADD PRIMARY KEY (`user_id`),
  ADD KEY `idx_blocked_drivers_blocked_at` (`blocked_at`);

--
-- Indexes for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_chat_messages_group_created` (`group_name`,`created_at`),
  ADD KEY `idx_chat_messages_user_id` (`user_id`),
  ADD KEY `idx_chat_messages_group_created_id` (`group_name`,`created_at`,`id`);

--
-- Indexes for table `flight_data`
--
ALTER TABLE `flight_data`
  ADD PRIMARY KEY (`flight_id`),
  ADD KEY `idx_flight_data_scheduled_time` (`scheduled_time`),
  ADD KEY `idx_flight_data_arrival_time` (`is_arrival`,`scheduled_time`),
  ADD KEY `idx_flight_data_flight_number` (`flight_number`),
  ADD KEY `idx_flight_data_airline` (`airline`),
  ADD KEY `idx_flight_data_destination` (`destination`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notifications_user_id` (`user_id`),
  ADD KEY `idx_notifications_sent_at` (`sent_at`),
  ADD KEY `idx_notifications_type` (`type`);

--
-- Indexes for table `parking_lots`
--
ALTER TABLE `parking_lots`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_parking_lots_name` (`name`),
  ADD KEY `idx_parking_lots_active` (`is_active`);

--
-- Indexes for table `price_alerts`
--
ALTER TABLE `price_alerts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_price_alerts_user_id` (`user_id`),
  ADD KEY `idx_price_alerts_created_at` (`created_at`),
  ADD KEY `idx_price_alerts_created_id` (`created_at`,`id`);

--
-- Indexes for table `price_alert_likes`
--
ALTER TABLE `price_alert_likes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_price_alert_likes_alert_user` (`alert_id`,`user_id`),
  ADD KEY `idx_price_alert_likes_alert_id_type` (`alert_id`,`type`),
  ADD KEY `idx_price_alert_likes_user_id` (`user_id`);

--
-- Indexes for table `suggestions`
--
ALTER TABLE `suggestions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_suggestions_user_id` (`user_id`),
  ADD KEY `idx_suggestions_status_created` (`status`,`created_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `idx_users_last_sign_in` (`last_sign_in`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `active_users`
--
ALTER TABLE `active_users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `app_config`
--
ALTER TABLE `app_config`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chat_messages`
--
ALTER TABLE `chat_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=92;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=171;

--
-- AUTO_INCREMENT for table `parking_lots`
--
ALTER TABLE `parking_lots`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `price_alerts`
--
ALTER TABLE `price_alerts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `price_alert_likes`
--
ALTER TABLE `price_alert_likes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `suggestions`
--
ALTER TABLE `suggestions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

-- --------------------------------------------------------

--
-- Structure for view `active_users_count`
--
DROP TABLE IF EXISTS `active_users_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`p4fm9jbmve84`@`localhost` SQL SECURITY DEFINER VIEW `active_users_count`  AS SELECT `au`.`location_name` AS `location_name`, count(0) AS `active_count` FROM `active_users` AS `au` WHERE `au`.`status` = 'active' AND `au`.`last_seen` > current_timestamp() - interval 5 minute GROUP BY `au`.`location_name` ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `active_users`
--
ALTER TABLE `active_users`
  ADD CONSTRAINT `fk_active_users_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `admin_users`
--
ALTER TABLE `admin_users`
  ADD CONSTRAINT `fk_admin_users_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `blocked_drivers`
--
ALTER TABLE `blocked_drivers`
  ADD CONSTRAINT `fk_blocked_drivers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `fk_chat_messages_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `price_alerts`
--
ALTER TABLE `price_alerts`
  ADD CONSTRAINT `fk_price_alerts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `price_alert_likes`
--
ALTER TABLE `price_alert_likes`
  ADD CONSTRAINT `fk_price_alert_likes_alert` FOREIGN KEY (`alert_id`) REFERENCES `price_alerts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_price_alert_likes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `suggestions`
--
ALTER TABLE `suggestions`
  ADD CONSTRAINT `fk_suggestions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
