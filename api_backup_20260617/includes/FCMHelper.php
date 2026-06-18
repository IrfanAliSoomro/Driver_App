<?php
/**
 * FCM Helper Functions
 * This file contains Firebase Cloud Messaging notification functions
 */

require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/FirebaseHelper.php';
require_once __DIR__ . '/FirebaseConfig.php';

/**
 * Send FCM notification to specific user.
 *
 * @param array<string,mixed> $data
 * @param array{channel_id?:string} $options
 */
function sendFCMNotification($userId, $title, $body, $data = [], $options = []) {
    try {
        $channelId = $options['channel_id'] ?? 'important_notifications';

        // Get user's FCM token
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("SELECT fcm_token FROM users WHERE user_id = :user_id AND fcm_token IS NOT NULL AND fcm_token != ''");
        $stmt->execute([':user_id' => $userId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$result || empty($result['fcm_token'])) {
            error_log("FCM skipped — no token for user: $userId");
            return false;
        }
        
        $fcmToken = $result['fcm_token'];

        if (!isFirebaseConfigured()) {
            error_log('FCM skipped — Firebase not configured on server (ride/chat push disabled)');
            return false;
        }

        $dataString = [];
        foreach ($data as $key => $value) {
            $dataString[$key] = (string)$value;
        }

        $accessToken = generateFirebaseAccessToken();
        if ($accessToken) {
            return sendFCMNotificationV1($fcmToken, $title, $body, $dataString, $channelId, $accessToken, $userId);
        }

        return sendFCMNotificationLegacyToken($fcmToken, $title, $body, $dataString, $userId);
    } catch (Exception $e) {
        error_log("Error sending FCM notification: " . $e->getMessage());
        return false;
    }
}

function sendFCMNotificationV1($fcmToken, $title, $body, array $dataString, $channelId, $accessToken, $userId) {
    $config = require __DIR__ . '/../config/config.php';
    $projectId = $config['firebase']['project_id'] ?? '';
    
    if (empty($projectId) || $projectId === 'your-project-id') {
        error_log('Firebase project ID not configured');
        return false;
    }

    $notificationPayload = [
        'message' => [
            'token' => $fcmToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $dataString,
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'sound' => 'default',
                    'channel_id' => $channelId,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-push-type' => 'alert',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'alert' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                    ],
                ],
            ],
        ],
    ];

    $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($notificationPayload),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $accessToken,
        ],
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($httpCode === 200) {
        error_log("FCM sent to user $userId (channel=$channelId)");
        return true;
    }

    error_log("FCM v1 failed for user $userId: HTTP $httpCode - $response - $curlError");

    // Invalid token — clear so app re-registers on next login
    if ($httpCode === 404 || (strpos((string)$response, 'UNREGISTERED') !== false)) {
        clearInvalidFcmToken($userId);
    }

    return false;
}

function sendFCMNotificationLegacyToken($fcmToken, $title, $body, array $dataString, $userId) {
    $config = require __DIR__ . '/../config/config.php';
    $serverKey = $config['firebase']['server_key'] ?? '';

    if (empty($serverKey) || $serverKey === 'your-server-key') {
        error_log('FCM legacy fallback unavailable — FIREBASE_SERVER_KEY not set');
        return false;
    }

    $fields = [
        'to' => $fcmToken,
        'priority' => 'high',
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
        ],
        'data' => $dataString,
    ];

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => 'https://fcm.googleapis.com/fcm/send',
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($fields),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: key=' . $serverKey,
        ],
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $json = json_decode($response, true);
        if (!empty($json['success'])) {
            error_log("FCM legacy sent to user $userId");
            return true;
        }
    }

    error_log("FCM legacy failed for user $userId: HTTP $httpCode - $response");
    return false;
}

function clearInvalidFcmToken($userId) {
    try {
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("UPDATE users SET fcm_token = NULL WHERE user_id = :user_id");
        $stmt->execute([':user_id' => $userId]);
        error_log("Cleared invalid FCM token for user $userId");
    } catch (Exception $e) {
        error_log("Failed to clear FCM token: " . $e->getMessage());
    }
}

/**
 * Send FCM notification to all admin users
 */
function sendNotificationToAdmins($title, $body, $data = []) {
    try {
        error_log("📧 Starting notification to admins: $title - $body");
        
        // Get all admin user IDs and their FCM tokens
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("SELECT u.user_id, u.fcm_token, u.display_name 
                              FROM users u 
                              INNER JOIN admin_users au ON u.user_id = au.user_id 
                              WHERE u.fcm_token IS NOT NULL AND u.fcm_token != ''");
        $stmt->execute();
        $admins = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        error_log("Found " . count($admins) . " admins with FCM tokens");
        
        $successCount = 0;
        foreach ($admins as $admin) {
            error_log("Sending notification to admin: {$admin['user_id']} ({$admin['display_name']})");
            if (sendFCMNotification($admin['user_id'], $title, $body, $data)) {
                $successCount++;
                error_log("✅ Notification sent successfully to {$admin['user_id']}");
            } else {
                error_log("❌ Failed to send notification to {$admin['user_id']}");
            }
        }
        
        error_log("📧 Final result: Sent notification to $successCount out of " . count($admins) . " admins");
        return $successCount > 0;
    } catch (Exception $e) {
        error_log("❌ Error sending notification to admins: " . $e->getMessage());
        error_log("Stack trace: " . $e->getTraceAsString());
        return false;
    }
}

/**
 * Send notification when user is promoted to admin
 */
function notifyAdminPromotion($userId, $userDisplayName = null) {
    try {
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("SELECT display_name, email FROM users WHERE user_id = :user_id");
        $stmt->execute([':user_id' => $userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $displayName = $userDisplayName ?? $user['display_name'] ?? 'User';
        
        $title = "🎉 You're Now an Admin!";
        $body = "Congratulations! You've been promoted to admin status.";
        $data = [
            'type' => 'admin_promotion',
            'user_id' => $userId,
            'title' => 'Admin Promotion',
            'message' => "You've been promoted to admin!"
        ];
        
        return sendFCMNotification($userId, $title, $body, $data);
    } catch (Exception $e) {
        error_log("Error notifying admin promotion: " . $e->getMessage());
        return false;
    }
}

/**
 * Send notification to admins when new suggestion is submitted
 */
function notifyAdminsNewSuggestion($suggestionId, $driverName, $title) {
    $notificationTitle = "💡 New Driver Suggestion";
    $notificationBody = "$driverName submitted: $title";
    $data = [
        'type' => 'new_suggestion',
        'suggestion_id' => $suggestionId,
        'driver_name' => $driverName,
        'suggestion_title' => $title
    ];
    
    return sendNotificationToAdmins($notificationTitle, $notificationBody, $data);
}

/**
 * Send notification to user when they are blocked
 */
function notifyDriverBlocked($userId, $reason = null) {
    try {
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("SELECT display_name, email FROM users WHERE user_id = :user_id");
        $stmt->execute([':user_id' => $userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $displayName = $user['display_name'] ?? 'Driver';
        
        $title = "⚠️ Account Blocked";
        $body = "Your account has been blocked" . ($reason ? ": $reason" : " due to violation of community guidelines.");
        
        $data = [
            'type' => 'account_blocked',
            'user_id' => $userId,
            'title' => 'Account Blocked',
            'message' => $body,
            'reason' => $reason ?? 'Violation of community guidelines'
        ];
        
        return sendFCMNotification($userId, $title, $body, $data);
    } catch (Exception $e) {
        error_log("Error notifying driver block: " . $e->getMessage());
        return false;
    }
}

/**
 * Send notification to user when they are unblocked
 */
function notifyDriverUnblocked($userId) {
    try {
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("SELECT display_name, email FROM users WHERE user_id = :user_id");
        $stmt->execute([':user_id' => $userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $displayName = $user['display_name'] ?? 'Driver';
        
        $title = "✅ Account Unblocked";
        $body = "Your account has been unblocked. You can now use all features again.";
        
        $data = [
            'type' => 'account_unblocked',
            'user_id' => $userId,
            'title' => 'Account Unblocked',
            'message' => $body,
            'action' => 'refresh'
        ];
        
        return sendFCMNotification($userId, $title, $body, $data);
    } catch (Exception $e) {
        error_log("Error notifying driver unblock: " . $e->getMessage());
        return false;
    }
}
