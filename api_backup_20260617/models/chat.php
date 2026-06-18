<?php
/**
 * Chat Endpoints
 * GET /api/chat/{group} - Get messages for a group
 * POST /api/chat/{group} - Send a message to a group
 * DELETE /api/chat/{messageId} - Delete a message
 * GET /api/chat/exists/{group} - Check if chat group exists and has messages
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/FirebaseHelper.php';
require_once __DIR__ . '/../models/ChatModel.php';
require_once __DIR__ . '/../models/UserModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$groupOrId = $segments[2] ?? null;
$action = $segments[3] ?? null;

// Handle /api/chat/exists/{group} route
if ($groupOrId === 'exists' && $action) {
    switch ($requestMethod) {
        case 'GET':
            checkGroupExists($action);
            return;
        default:
            Response::error('Method not allowed', 405);
            return;
    }
}

// Handle regular routes
switch ($requestMethod) {
    case 'GET':
        getMessages($groupOrId);
        break;
        
    case 'POST':
        $authUser = $auth->requireAuth();
        sendMessage($groupOrId, $authUser);
        break;
        
    case 'DELETE':
        $authUser = $auth->requireAuth();
        deleteMessage($groupOrId, $authUser);
        break;
        
    default:
        Response::error('Method not allowed', 405);
}

/**
 * Get messages for a group
 */
function getMessages($group) {
    if (!$group || !in_array($group, ['midway', 'ohare'])) {
        Response::error('Invalid group. Must be "midway" or "ohare"', 400);
        return;
    }
    
    $limit = $_GET['limit'] ?? 50;
    $offset = $_GET['offset'] ?? 0;
    $after = $_GET['after'] ?? null;
    
    $model = new ChatModel();
    
    if ($after) {
        $messages = $model->getAfterTimestamp($group, $after);
    } else {
        $messages = $model->getByGroup($group, $limit, $offset);
    }
    
    Response::success([
        'messages' => $messages,
        'group' => $group
    ]);
}

/**
 * Send a message to a group with notifications to all users
 */
function sendMessage($group, $authUser) {
    if (!$group || !in_array($group, ['midway', 'ohare'])) {
        Response::error('Invalid group. Must be "midway" or "ohare"', 400);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['text'])) {
        Response::error('Message text is required', 400);
        return;
    }
    
    $messageData = [
        'group' => $group,
        'user_id' => $authUser['user_id'],
        'text' => Validator::sanitizeChatPlainText($data['text'])
    ];
    
    $model = new ChatModel();
    $messageId = $model->create($messageData);
    
    if ($messageId) {
        // Send notifications to all registered users
        sendChatNotifications($group, $authUser, $data['text'], $messageId);
        
        Response::success([
            'message_id' => $messageId,
            'group' => $group
        ], 'Message sent successfully', 201);
    } else {
        Response::error('Failed to send message', 500);
    }
}

/**
 * Delete a message
 */
function deleteMessage($messageId, $authUser) {
    if (!$messageId) {
        Response::error('Message ID is required', 400);
        return;
    }
    
    $model = new ChatModel();
    $result = $model->delete($messageId, $authUser['user_id']);
    
    if ($result) {
        Response::success(null, 'Message deleted successfully');
    } else {
        Response::error('Failed to delete message or unauthorized', 403);
    }
}

/**
 * Check if a chat group exists and has messages
 */
function checkGroupExists($group) {
    if (!$group || !in_array($group, ['midway', 'ohare'])) {
        Response::success([
            'exists' => false,
            'group' => $group,
            'message_count' => 0
        ]);
        return;
    }
    
    $model = new ChatModel();
    $messageCount = $model->getMessageCount($group);
    
    Response::success([
        'exists' => true,
        'group' => $group,
        'message_count' => $messageCount,
        'has_messages' => $messageCount > 0
    ]);
}

/**
 * Send notifications to all registered users when a message is sent
 */
function sendChatNotifications($group, $sender, $messageText, $messageId) {
    try {
        $userModel = new UserModel();
        
        // Get all active users (excluding the sender)
        $users = $userModel->getActiveUsers(1000);
        
        error_log('Active users found: ' . count($users));
        
        $fcmTokens = [];
        $recipientIds = [];
        
        foreach ($users as $user) {
            // Skip the sender
            if ($user['user_id'] === $sender['user_id']) {
                continue;
            }
            
            // Only send to users with FCM tokens
            if (!empty($user['fcm_token'])) {
                $fcmTokens[] = $user['fcm_token'];
                $recipientIds[] = $user['user_id'];
                error_log('Added FCM token for user: ' . $user['user_id']);
            } else {
                error_log('No FCM token for user: ' . $user['user_id']);
            }
        }
        
        if (empty($fcmTokens)) {
            error_log('No FCM tokens found for chat notifications');
            return;
        }
        
        // Prepare notification data
        $senderName = $sender['display_name'] ?? 'Driver';
        $groupName = ucfirst($group) . ' Airport';
        
        $title = "New message in $groupName";
        $body = "$senderName: " . substr($messageText, 0, 50) . (strlen($messageText) > 50 ? '...' : '');
        
        $data = [
            'type' => 'chat_message',
            'group' => $group,
            'message_id' => $messageId,
            'sender_id' => $sender['user_id'],
            'sender_name' => $senderName,
            'action' => 'open_chat'
        ];
        
        // Send FCM notification using REST API
        $result = sendFCMNotificationREST($fcmTokens, $title, $body, $data);
        
        if ($result) {
            // Log notification for each recipient
            foreach ($recipientIds as $userId) {
                logNotification(
                    $userId,
                    $title,
                    $body,
                    $data,
                    'chat_message',
                    false
                );
            }
            
            error_log("Chat notifications sent to " . count($fcmTokens) . " users");
        } else {
            error_log("Failed to send chat notifications");
        }
        
    } catch (Exception $e) {
        error_log("Error sending chat notifications: " . $e->getMessage());
    }
}

/**
 * Send FCM notification via Firebase Cloud Messaging REST API (Batch Method)
 */
function sendFCMNotificationREST($tokens, $title, $body, $data = []) {
    $config = require __DIR__ . '/../config/config.php';
    $projectId = $config['firebase']['project_id'];
    
    if (empty($projectId) || $projectId === 'your-project-id') {
        error_log('Firebase project ID not configured');
        return false;
    }
    
    // Generate access token using service account
    $accessToken = generateFirebaseAccessToken();
    if (!$accessToken) {
        error_log('Failed to generate Firebase access token');
        return false;
    }
    
    // Use REST API batch endpoint for better performance
    $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
    
    $successCount = 0;
    $failureCount = 0;
    
    // Process tokens in batches of 500 (FCM limit)
    $tokenBatches = array_chunk($tokens, 500);
    
    foreach ($tokenBatches as $batch) {
        $batchResults = sendFCMBatch($batch, $title, $body, $data, $projectId, $accessToken);
        $successCount += $batchResults['success'];
        $failureCount += $batchResults['failure'];
    }
    
    error_log("FCM notifications sent: $successCount success, $failureCount failures");
    return $successCount > 0;
}

/**
 * Send FCM batch notification
 */
function sendFCMBatch($tokens, $title, $body, $data, $projectId, $accessToken) {
    $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
    
    $successCount = 0;
    $failureCount = 0;
    
    // Send to each token individually for better error handling
    foreach ($tokens as $token) {
        $message = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body
                ],
                'data' => $data,
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'sound' => 'default',
                        'channel_id' => 'chat_notifications',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                    ]
                ],
                'apns' => [
                    'headers' => [
                        'apns-priority' => '10',
                        'apns-push-type' => 'alert'
                    ],
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                            'alert' => [
                                'title' => $title,
                                'body' => $body
                            ]
                        ]
                    ]
                ],
                'webpush' => [
                    'headers' => [
                        'TTL' => '86400'
                    ],
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                        'icon' => '/icon-192x192.png',
                        'badge' => '/badge-72x72.png'
                    ]
                ]
            ]
        ];
        
        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json'
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);
        
        if ($httpCode === 200) {
            $response = json_decode($result, true);
            if (isset($response['name'])) {
                $successCount++;
            } else {
                $failureCount++;
                error_log("FCM response error for token: $result");
            }
        } else {
            $failureCount++;
            error_log("FCM send failed for token: HTTP $httpCode - $result - Error: $curlError");
        }
    }
    
    return ['success' => $successCount, 'failure' => $failureCount];
}

/**
 * Alternative: Send FCM notification via Legacy HTTP API (Fallback)
 */
function sendFCMNotificationLegacy($tokens, $title, $body, $data = []) {
    $config = require __DIR__ . '/../config/config.php';
    $serverKey = $config['firebase']['server_key'];
    
    if (empty($serverKey) || $serverKey === 'your-server-key') {
        error_log('Firebase server key not configured');
        return false;
    }
    
    $notification = [
        'title' => $title,
        'body' => $body,
        'sound' => 'default',
        'badge' => 1
    ];
    
    $fields = [
        'registration_ids' => $tokens,
        'notification' => $notification,
        'data' => $data,
        'priority' => 'high',
        'content_available' => true
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
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        $response = json_decode($result, true);
        if (isset($response['success']) && $response['success'] > 0) {
            error_log("Legacy FCM: {$response['success']} success, {$response['failure']} failures");
            return true;
        }
    }
    
    error_log("Legacy FCM send failed: HTTP $httpCode - $result");
    return false;
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

