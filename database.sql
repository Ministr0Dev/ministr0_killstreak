-- Ministr0 Dev — Killstreak System Database | discord.gg/4eh8
-- © 2026 Ministr0 Dev. All rights reserved.

CREATE DATABASE IF NOT EXISTS `ministr0_killstreak` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ministr0_killstreak`;

CREATE TABLE IF NOT EXISTS `ministr0_killstreaks` (
    `id`                INT             AUTO_INCREMENT PRIMARY KEY,
    `identifier`        VARCHAR(60)     NOT NULL UNIQUE,
    `name`              VARCHAR(100)    DEFAULT 'Unknown',
    `best_streak`       INT             DEFAULT 0,
    `total_kills`       INT             DEFAULT 0,
    `streaks_earned`    INT             DEFAULT 0,
    `last_streak_date`  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at`        TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_best_streak` (`best_streak` DESC),
    INDEX `idx_last_streak_date` (`last_streak_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ministr0_killstreak_milestones` (
    `id`                INT             AUTO_INCREMENT PRIMARY KEY,
    `identifier`        VARCHAR(60)     NOT NULL,
    `player_name`       VARCHAR(100)    DEFAULT 'Unknown',
    `streak_reached`    INT             NOT NULL,
    `tier_title`        VARCHAR(50)     DEFAULT '',
    `rewards_given`     TEXT,
    `achieved_at`       TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_streak` (`streak_reached` DESC),
    INDEX `idx_achieved_at` (`achieved_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ministr0_killstreak_admin_log` (
    `id`                INT             AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier`  VARCHAR(60)     NOT NULL,
    `admin_name`        VARCHAR(100)    DEFAULT 'Unknown',
    `action`            VARCHAR(50)     NOT NULL,
    `target_identifier` VARCHAR(60)     DEFAULT NULL,
    `target_name`       VARCHAR(100)    DEFAULT NULL,
    `details`           TEXT,
    `timestamp`         TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Developed by Ministr0 Dev | discord.gg/4eh8
