<?php

/**
 * Pushes real-time events to the Node WebSocket server (internal HTTP API).
 */
class WebSocketPublisher {
    private static $config;

    private static function config() {
        if (self::$config === null) {
            $cfg = require __DIR__ . '/../config/config.php';
            self::$config = $cfg['websocket'] ?? [];
        }
        return self::$config;
    }

    public static function isEnabled() {
        $c = self::config();
        return !empty($c['enabled']);
    }

    /**
     * @param array<string,mixed> $payload
     */
    public static function publish($event, array $payload = []) {
        if (!self::isEnabled()) {
            return false;
        }

        $c = self::config();
        $url = rtrim($c['internal_url'] ?? 'http://127.0.0.1:8081', '/') . '/internal/broadcast';

        $body = json_encode([
            'event' => $event,
            'payload' => $payload,
            'ts' => time(),
        ]);

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $body,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'X-WS-Secret: ' . ($c['secret'] ?? ''),
            ],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 2,
            CURLOPT_CONNECTTIMEOUT => 1,
        ]);

        $result = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($code !== 200) {
            error_log("WebSocketPublisher failed: HTTP $code event=$event response=" . substr((string)$result, 0, 200));
            return false;
        }

        return true;
    }

    public static function chatMessageNew($group, array $message) {
        return self::publish('chat.message.new', [
            'group' => $group,
            'message' => $message,
        ]);
    }

    public static function chatMessageDeleted($group, $messageId) {
        return self::publish('chat.message.deleted', [
            'group' => $group,
            'message_id' => (int)$messageId,
        ]);
    }

    public static function presenceCounts(array $counts) {
        return self::publish('presence.counts', [
            'counts' => $counts,
        ]);
    }

    /**
     * @param string|null $targetUserId null = broadcast to notifications subscribers
     */
    public static function notification($title, $body, array $data = [], $type = 'general', $targetUserId = null) {
        return self::publish('notification', [
            'user_id' => $targetUserId,
            'title' => $title,
            'body' => $body,
            'data' => $data,
            'type' => $type,
        ]);
    }

    public static function priceAlertNew(array $priceAlert) {
        return self::publish('price_alert.new', [
            'price_alert' => $priceAlert,
        ]);
    }

    public static function priceAlertUpdated(array $priceAlert) {
        return self::publish('price_alert.updated', [
            'price_alert' => $priceAlert,
        ]);
    }

    public static function priceAlertDeleted($alertId) {
        return self::publish('price_alert.deleted', [
            'alert_id' => (int)$alertId,
        ]);
    }
}
