<?php
/**
 * Chat Endpoints
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/ChatGroupHelper.php';
require_once __DIR__ . '/../includes/WebSocketPublisher.php';
require_once __DIR__ . '/../models/ChatModel.php';
require_once __DIR__ . '/../models/UserModel.php';
require_once __DIR__ . '/../models/AdminModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$groupOrId = $segments[2] ?? null;
$action = $segments[3] ?? null;

if ($groupOrId === 'bulk-delete' && $requestMethod === 'POST') {
    $authUser = $auth->requireAuth();
    bulkDeleteMessages($authUser);
    return;
}

if ($groupOrId === 'exists' && $action) {
    if ($requestMethod === 'GET') {
        checkGroupExists($action);
        return;
    }
    Response::error('Method not allowed', 405);
    return;
}

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

function validateGroup($group) {
    if (!ChatGroupHelper::isValidGroupSlug($group)) {
        Response::error('Invalid group id', 400);
        return false;
    }
    return true;
}

function getMessages($group) {
    if (!validateGroup($group)) {
        return;
    }

    $limit = (int)($_GET['limit'] ?? 50);
    $offset = (int)($_GET['offset'] ?? 0);
    $after = $_GET['after'] ?? null;

    $model = new ChatModel();
    if ($after) {
        $messages = $model->getAfterTimestamp($group, $after);
    } else {
        $messages = $model->getByGroup($group, $limit, $offset);
    }

    Response::success(['messages' => $messages, 'group' => $group]);
}

function sendMessage($group, $authUser) {
    if (!validateGroup($group)) {
        return;
    }

    $data = json_decode(file_get_contents('php://input'), true);
    if (empty($data['text'])) {
        Response::error('Message text is required', 400);
        return;
    }

    $model = new ChatModel();
    $replyToId = isset($data['reply_to_message_id']) ? (int)$data['reply_to_message_id'] : null;
    if ($replyToId <= 0) {
        $replyToId = null;
    }

    if ($replyToId !== null) {
        $parent = $model->getById($replyToId);
        if (!$parent || ($parent['group_name'] ?? '') !== $group) {
            Response::error('Invalid reply_to_message_id for this group', 400);
            return;
        }
    }

    $messageId = $model->create([
        'group' => $group,
        'user_id' => $authUser['user_id'],
        'text' => Validator::sanitizeChatPlainText($data['text']),
        'reply_to_message_id' => $replyToId,
    ]);

    if (!$messageId) {
        Response::error('Failed to send message', 500);
        return;
    }

    $message = $model->getById($messageId);
    if ($message) {
        $message['group'] = $group;
        WebSocketPublisher::chatMessageNew($group, $message);
    }

    notifyChatRecipients($group, $authUser, $data['text'], $messageId);

    Response::success([
        'message_id' => $messageId,
        'group' => $group,
        'message' => $message,
    ], 'Message sent successfully', 201);
}

function deleteMessage($messageId, $authUser) {
    if (!$messageId) {
        Response::error('Message ID is required', 400);
        return;
    }

    $model = new ChatModel();
    $existing = $model->getById($messageId);
    if (!$existing) {
        Response::error('Message not found', 404);
        return;
    }

    $group = $existing['group_name'] ?? null;
    $result = $model->delete($messageId, $authUser['user_id']);

    if ($result && $group) {
        WebSocketPublisher::chatMessageDeleted($group, $messageId);
        Response::success(null, 'Message deleted successfully');
        return;
    }

    Response::error('Failed to delete message or unauthorized', 403);
}

/**
 * POST /api/chat/bulk-delete
 * Body: { "message_ids": [1, 2, 3] }
 */
function bulkDeleteMessages($authUser) {
    $data = json_decode(file_get_contents('php://input'), true) ?: [];
    $ids = $data['message_ids'] ?? $data['ids'] ?? null;

    if (!is_array($ids) || empty($ids)) {
        Response::error('message_ids array is required', 400);
        return;
    }

    $model = new ChatModel();
    $adminModel = new AdminModel();
    $isAdmin = $adminModel->isAdmin($authUser['user_id']);

    $deletedIds = [];
    $failedIds = [];

    foreach ($ids as $rawId) {
        $id = (int)$rawId;
        if ($id <= 0) {
            continue;
        }

        $existing = $model->getById($id);
        if (!$existing) {
            $failedIds[] = $id;
            continue;
        }

        $group = $existing['group_name'] ?? null;
        $ok = $isAdmin
            ? $model->deleteAny($id)
            : $model->delete($id, $authUser['user_id']);

        if ($ok) {
            $deletedIds[] = $id;
            if ($group) {
                WebSocketPublisher::chatMessageDeleted($group, $id);
            }
        } else {
            $failedIds[] = $id;
        }
    }

    if (empty($deletedIds)) {
        Response::error('No messages deleted (not found or unauthorized)', 403);
        return;
    }

    Response::success([
        'deleted_count' => count($deletedIds),
        'deleted_ids' => $deletedIds,
        'failed_ids' => $failedIds,
    ], 'Messages deleted successfully');
}

function notifyChatRecipients($group, $sender, $messageText, $messageId) {
    notifyChatWebSocket($group, $sender, $messageText, $messageId);
    notifyChatFcm($group, $sender, $messageText, $messageId);
}

/**
 * Real-time in-app alert for users subscribed to the notifications WS channel.
 */
function notifyChatWebSocket($group, $sender, $messageText, $messageId) {
    $userModel = new UserModel();
    $users = $userModel->getActiveUsers(1000);
    $senderName = $sender['display_name'] ?? 'Driver';
    $title = 'New message in ' . ucfirst($group);
    $body = $senderName . ': ' . mb_substr($messageText, 0, 50);
    $data = [
        'type' => 'chat_message',
        'group' => $group,
        'message_id' => (string)$messageId,
    ];

    foreach ($users as $user) {
        if ($user['user_id'] === $sender['user_id']) {
            continue;
        }
        WebSocketPublisher::notification(
            $title,
            $body,
            $data,
            'chat_message',
            $user['user_id']
        );
    }
}

function notifyChatFcm($group, $sender, $messageText, $messageId) {
    if (!function_exists('sendFCMNotification')) {
        require_once __DIR__ . '/../includes/FCMHelper.php';
    }
    $userModel = new UserModel();
    $users = $userModel->getActiveUsers(1000);
    foreach ($users as $user) {
        if ($user['user_id'] === $sender['user_id'] || empty($user['fcm_token'])) {
            continue;
        }
        $senderName = $sender['display_name'] ?? 'Driver';
        sendFCMNotification(
            $user['user_id'],
            'New message in ' . ucfirst($group),
            $senderName . ': ' . mb_substr($messageText, 0, 50),
            [
                'type' => 'chat_message',
                'group' => $group,
                'message_id' => (string)$messageId,
            ]
        );
    }
}

function checkGroupExists($group) {
    if (!ChatGroupHelper::isValidGroupSlug($group)) {
        Response::success([
            'exists' => false,
            'group' => $group,
            'message_count' => 0,
        ]);
        return;
    }

    $model = new ChatModel();
    $messageCount = $model->getMessageCount($group);

    Response::success([
        'exists' => true,
        'group' => $group,
        'message_count' => $messageCount,
        'has_messages' => $messageCount > 0,
    ]);
}
