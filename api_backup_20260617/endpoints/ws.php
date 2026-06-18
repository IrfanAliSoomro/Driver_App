<?php
/**
 * WebSocket connection info for clients
 * GET /api/ws
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/JWT.php';
require_once __DIR__ . '/../includes/FirebaseConfig.php';

$config = require __DIR__ . '/../config/config.php';
$ws = $config['websocket'] ?? [];

$user = null;
$headers = function_exists('getallheaders') ? getallheaders() : [];
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? $_GET['token'] ?? null;
if ($authHeader && preg_match('/Bearer\s+(.*)$/i', $authHeader, $m)) {
    $user = JWT::decode($m[1]);
} elseif (!empty($_GET['token'])) {
    $user = JWT::decode($_GET['token']);
}

Response::success([
    'enabled' => !empty($ws['enabled']),
    'url' => $ws['public_url'] ?? null,
    'fcm_configured' => isFirebaseConfigured(),
    'protocol' => [
        'auth' => 'Send JSON after connect: {"type":"auth","token":"<JWT>"} or connect with ?token=<JWT>',
        'subscribe' => [
            'chat' => '{"type":"subscribe","channel":"chat","group":"ohare"}',
            'presence' => '{"type":"subscribe","channel":"presence"}',
            'notifications' => '{"type":"subscribe","channel":"notifications"}',
            'price_alerts' => '{"type":"subscribe","channel":"price_alerts"}',
        ],
        'events' => [
            'chat.message.new',
            'chat.message.deleted',
            'presence.counts',
            'notification',
            'price_alert.new',
            'price_alert.updated',
            'price_alert.deleted',
        ],
    ],
    'user_id' => $user['user_id'] ?? null,
]);
