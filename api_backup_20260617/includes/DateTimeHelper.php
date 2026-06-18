<?php

/**
 * Normalize MySQL datetime strings (session UTC) to ISO 8601 UTC for API consumers.
 */
class DateTimeHelper {
    /**
     * @param string|null $mysqlDatetime Value from MySQL DATETIME/TIMESTAMP
     * @return string|null e.g. 2026-04-20T09:30:50Z
     */
    public static function mysqlToIso8601Utc($mysqlDatetime) {
        if ($mysqlDatetime === null || $mysqlDatetime === '') {
            return null;
        }
        try {
            $dt = new DateTimeImmutable($mysqlDatetime, new DateTimeZone('UTC'));
            return $dt->format('Y-m-d\TH:i:s\Z');
        } catch (Exception $e) {
            return $mysqlDatetime;
        }
    }

    /**
     * @param array<string,mixed> $row
     * @param string[] $keys
     * @return array<string,mixed>
     */
    public static function rowDatetimeKeysToIso8601Utc(array $row, array $keys) {
        foreach ($keys as $key) {
            if (array_key_exists($key, $row) && $row[$key] !== null) {
                $row[$key] = self::mysqlToIso8601Utc((string) $row[$key]);
            }
        }
        return $row;
    }

    /** Current instant as ISO 8601 UTC (for fallbacks when DB row is missing). */
    public static function nowIso8601Utc() {
        return (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d\TH:i:s\Z');
    }

    /**
     * Parse client `after` (ISO8601 or legacy datetime) to MySQL DATETIME string in UTC for SQL comparison.
     */
    public static function clientAfterToMysqlUtc($after) {
        if ($after === null || $after === '') {
            return '';
        }
        try {
            $dt = new DateTimeImmutable(trim($after));
            return $dt->setTimezone(new DateTimeZone('UTC'))->format('Y-m-d H:i:s');
        } catch (Exception $e) {
            return trim((string) $after);
        }
    }
}
