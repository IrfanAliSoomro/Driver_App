<?php

require_once __DIR__ . '/Database.php';

class ActiveUsersHelper {
    /**
     * Active user counts per parking lot (last 5 minutes).
     *
     * @return array<string,int>
     */
    public static function getCounts() {
        $db = Database::getInstance();

        $lots = $db->fetchAll(
            "SELECT name FROM parking_lots WHERE is_active = 1 ORDER BY name"
        );

        $counts = [];
        foreach ($lots as $lot) {
            $counts[$lot['name']] = 0;
        }

        $rows = $db->fetchAll(
            "SELECT location_name, COUNT(*) AS active_count
             FROM active_users
             WHERE status = 'active'
               AND last_seen > UTC_TIMESTAMP() - INTERVAL 5 MINUTE
             GROUP BY location_name"
        );

        foreach ($rows as $row) {
            $counts[$row['location_name']] = (int)$row['active_count'];
        }

        return $counts;
    }

    public static function publishCounts() {
        require_once __DIR__ . '/WebSocketPublisher.php';
        return WebSocketPublisher::presenceCounts(self::getCounts());
    }
}
