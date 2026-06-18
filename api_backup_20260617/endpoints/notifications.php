<?php
/**
 * Notifications Endpoints
 * POST /api/notifications/send - Send notification to specific user (admin only)
 * POST /api/notifications/broadcast - Broadcast notification to all users (admin only)
 * GET /api/notifications/history - Get notification history (admin only)
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../includes/WebSocketPublisher.php';
require_once __DIR__ . '/../models/AdminModel.php';
require_once __DIR__ . '/../models/UserModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$action = $segments[2] ?? '';

switch ($action) {
    case 'send':
        if ($requestMethod === 'POST') {
            $authUser = $auth->requireAuth();
            sendNotification($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'broadcast':
        if ($requestMethod === 'POST') {
            $authUser = $auth->requireAuth();
            broadcastNotification($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'history':
        if ($requestMethod === 'GET') {
            $authUser = $auth->requireAuth();
            getNotificationHistory($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    default:
        Response::error('Invalid notification endpoint', 404);
}

/**
 * Send notification to specific user (admin only)
 */
function sendNotification($authUser) {
    $adminModel = new AdminModel();
    
    // Check if user is admin
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $required = ['user_id', 'title', 'body'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    // Get user's FCM token
    $userModel = new UserModel();
    $user = $userModel->getUserById($data['user_id']);
    
    if (!$user || empty($user['fcm_token'])) {
        Response::error('User not found or FCM token not available', 404);
        return;
    }
    
    // Send FCM notification
    $result = sendFCMNotification(
        [$user['fcm_token']],
        $data['title'],
        $data['body'],
        $data['data'] ?? []
    );
    
    if ($result) {
        // Log notification
        logNotification(
            $data['user_id'],
            $data['title'],
            $data['body'],
            $data['data'] ?? [],
            $data['type'] ?? 'general',
            false
        );

        WebSocketPublisher::notification(
            $data['title'],
            $data['body'],
            $data['data'] ?? [],
            $data['type'] ?? 'general',
            $data['user_id']
        );
        
        Response::success(null, 'Notification sent successfully');
    } else {
        Response::error('Failed to send notification', 500);
    }
}

/**
 * Broadcast notification to all users (admin only)
 */
function broadcastNotification($authUser) {
    $adminModel = new AdminModel();
    
    // Check if user is admin
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $required = ['title', 'body'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    // Get all users with FCM tokens
    $userModel = new UserModel();
    $users = $userModel->getActiveUsers(1000);
    
    $fcmTokens = [];
    foreach ($users as $user) {
        if (!empty($user['fcm_token'])) {
            $fcmTokens[] = $user['fcm_token'];
        }
    }
    
    if (empty($fcmTokens)) {
        Response::error('No users with FCM tokens found', 404);
        return;
    }
    
    // Send FCM notification
    $result = sendFCMNotification(
        $fcmTokens,
        $data['title'],
        $data['body'],
        $data['data'] ?? []
    );
    
    if ($result) {
        // Log notification
        logNotification(
            null,
            $data['title'],
            $data['body'],
            $data['data'] ?? [],
            $data['type'] ?? 'broadcast',
            true
        );

        WebSocketPublisher::notification(
            $data['title'],
            $data['body'],
            $data['data'] ?? [],
            $data['type'] ?? 'broadcast',
            null
        );
        
        Response::success([
            'recipients_count' => count($fcmTokens)
        ], 'Broadcast notification sent successfully');
    } else {
        Response::error('Failed to send broadcast notification', 500);
    }
}

/**
 * Get notification history (admin only)
 */
function getNotificationHistory($authUser) {
    $adminModel = new AdminModel();
    
    // Check if user is admin
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $limit = $_GET['limit'] ?? 50;
    $offset = $_GET['offset'] ?? 0;
    
    try {
        $db = Database::getInstance()->getConnection();
        
        $sql = "SELECT * FROM notifications 
                ORDER BY sent_at DESC 
                LIMIT :limit OFFSET :offset";
        
        $stmt = $db->prepare($sql);
        $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Decode JSON data field
        foreach ($notifications as &$notification) {
            if (!empty($notification['data'])) {
                $notification['data'] = json_decode($notification['data'], true);
            }
        }
        
        Response::success(['notifications' => $notifications]);
    } catch (PDOException $e) {
        error_log("Error fetching notification history: " . $e->getMessage());
        Response::error('Failed to fetch notification history', 500);
    }
}

/**
 * Send FCM notification via Firebase Cloud Messaging
 */
function sendFCMNotification($tokens, $title, $body, $data = []) {
    $config = require __DIR__ . '/../config/config.php';
    $serverKey = $config['firebase']['server_key'];
    
    if (empty($serverKey) || $serverKey === 'your-server-key') {
        error_log('Firebase server key not configured');
        return false;
    }
    
    $notification = [
        'title' => $title,
        'body' => $body,
        'sound' => 'default'
    ];
    
    $fields = [
        'registration_ids' => $tokens,
        'notification' => $notification,
        'data' => $data,
        'priority' => 'high'
    ];
    
    $headers = [
        'Authorization: key=' . $serverKey,
        'Content-Type: application/json'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        return true;
    } else {
        error_log("FCM send failed: HTTP $httpCode - $result");
        return false;
    }
}

/**
 * Log notification to database
 */
function logNotification($userId, $title, $body, $data, $type, $isBroadcast) {
    try {
        $db = Database::getInstance()->getConnection();
        
        $sql = "INSERT INTO notifications 
                (user_id, title, body, data, type, is_broadcast, sent_at) 
                VALUES (:user_id, :title, :body, :data, :type, :is_broadcast, NOW())";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':user_id' => $userId,
            ':title' => $title,
            ':body' => $body,
            ':data' => json_encode($data),
            ':type' => $type,
            ':is_broadcast' => $isBroadcast ? 1 : 0
        ]);
        
        return true;
    } catch (PDOException $e) {
        error_log("Error logging notification: " . $e->getMessage());
        return false;
    }
}

