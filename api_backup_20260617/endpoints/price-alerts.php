<?php
/**
 * Price Alerts Endpoints
 * GET /api/price-alerts - Get all price alerts
 * GET /api/price-alerts/{id} - Get price alert by ID
 * POST /api/price-alerts - Create new price alert
 * PUT /api/price-alerts/{id} - Update price alert
 * DELETE /api/price-alerts/{id} - Delete price alert
 * POST /api/price-alerts/{id}/like - Like a price alert
 * POST /api/price-alerts/{id}/dislike - Dislike a price alert
 * DELETE /api/price-alerts/{id}/reaction - Remove reaction
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/WebSocketPublisher.php';
require_once __DIR__ . '/../includes/FirebaseConfig.php';
require_once __DIR__ . '/../models/PriceAlertModel.php';
require_once __DIR__ . '/../models/UserModel.php';
require_once __DIR__ . '/../models/AdminModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$alertId = $segments[2] ?? null;
$action = $segments[3] ?? null;

switch ($requestMethod) {
    case 'GET':
        if ($alertId) {
            getPriceAlert($alertId);
        } else {
            getPriceAlerts();
        }
        break;
        
    case 'POST':
        $authUser = $auth->requireAuth();
        if ($alertId) {
            // Handle reactions
            if ($action === 'like') {
                addReaction($alertId, $authUser, 'like');
            } elseif ($action === 'dislike') {
                addReaction($alertId, $authUser, 'dislike');
            } else {
                Response::error('Invalid action', 404);
            }
        } else {
            createPriceAlert($authUser);
        }
        break;
        
    case 'PUT':
        $authUser = $auth->requireAuth();
        updatePriceAlert($alertId, $authUser);
        break;
        
    case 'DELETE':
        $authUser = $auth->requireAuth();
        if ($action === 'reaction') {
            removeReaction($alertId, $authUser);
        } else {
            deletePriceAlert($alertId, $authUser);
        }
        break;
        
    default:
        Response::error('Method not allowed', 405);
}

/**
 * Get all price alerts
 */
function getPriceAlerts() {
    $limit = $_GET['limit'] ?? 50;
    $offset = $_GET['offset'] ?? 0;
    
    $model = new PriceAlertModel();
    $alerts = $model->getAll($limit, $offset);
    
    Response::success(['price_alerts' => $alerts]);
}

/**
 * Get price alert by ID
 */
function getPriceAlert($alertId) {
    $model = new PriceAlertModel();
    $alert = $model->getById($alertId);
    
    if (!$alert) {
        Response::error('Price alert not found', 404);
        return;
    }
    
    Response::success(['price_alert' => $alert]);
}

/**
 * Create new price alert
 */
function createPriceAlert($authUser) {
    // Check if user is blocked
    if (isUserBlocked($authUser['user_id'])) {
        Response::error('Your account has been blocked. You cannot create price alerts.', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $required = ['pickup', 'dropoff', 'price'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    if (!Validator::numeric($data['price'])) {
        Response::error('Price must be numeric', 400);
        return;
    }
    
    $data['user_id'] = $authUser['user_id'];
    
    $model = new PriceAlertModel();
    $alertId = $model->create($data);
    
    if ($alertId) {
        $alert = $model->getById($alertId);
        if ($alert) {
            publishPriceAlertCreated($alert, $authUser);
            Response::success(['price_alert' => $alert], 'Price alert created successfully', 201);
        } else {
            Response::error('Price alert created but failed to retrieve', 500);
        }
    } else {
        Response::error('Failed to create price alert - Please check your input data', 500);
    }
}

/**
 * Check if user is blocked
 */
function isUserBlocked($userId) {
    try {
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("SELECT COUNT(*) as count FROM blocked_drivers WHERE user_id = :user_id");
        $stmt->execute([':user_id' => $userId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        return $result['count'] > 0;
    } catch (PDOException $e) {
        error_log("Error checking if user is blocked: " . $e->getMessage());
        return false;
    }
}

/**
 * Update price alert
 */
function updatePriceAlert($alertId, $authUser) {
    // Check if user is blocked
    if (isUserBlocked($authUser['user_id'])) {
        Response::error('Your account has been blocked. You cannot update price alerts.', 403);
        return;
    }
    
    if (!$alertId) {
        Response::error('Alert ID is required', 400);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $model = new PriceAlertModel();
    $alert = $model->getById($alertId);
    
    if (!$alert) {
        Response::error('Price alert not found', 404);
        return;
    }
    
    // Only owner can update
    if ($alert['user_id'] !== $authUser['user_id']) {
        Response::error('Unauthorized', 403);
        return;
    }
    
    $result = $model->update($alertId, $data);
    
    if ($result) {
        $updated = $model->getById($alertId);
        if ($updated) {
            WebSocketPublisher::priceAlertUpdated($updated);
        }
        Response::success(['price_alert' => $updated], 'Price alert updated successfully');
    } else {
        Response::error('Failed to update price alert', 500);
    }
}

/**
 * Delete price alert
 */
function deletePriceAlert($alertId, $authUser) {
    if (!$alertId) {
        Response::error('Alert ID is required', 400);
        return;
    }

    $model = new PriceAlertModel();
    $alert = $model->getById($alertId);

    if (!$alert) {
        Response::error('Price alert not found', 404);
        return;
    }

    $adminModel = new AdminModel();
    $isAdmin = $adminModel->isAdmin($authUser['user_id']);

    if (!$isAdmin && isUserBlocked($authUser['user_id'])) {
        Response::error('Your account has been blocked. You cannot delete price alerts.', 403);
        return;
    }

    // Owner can delete their alert; admins can delete any alert
    if (!$isAdmin && $alert['user_id'] !== $authUser['user_id']) {
        Response::error('Unauthorized', 403);
        return;
    }

    $result = $model->delete($alertId);
    
    if ($result) {
        WebSocketPublisher::priceAlertDeleted($alertId);
        Response::success(null, 'Price alert deleted successfully');
    } else {
        Response::error('Failed to delete price alert', 500);
    }
}

/**
 * Add like/dislike to price alert
 */
function addReaction($alertId, $authUser, $type) {
    // Check if user is blocked
    if (isUserBlocked($authUser['user_id'])) {
        Response::error('Your account has been blocked. You cannot react to price alerts.', 403);
        return;
    }
    
    $model = new PriceAlertModel();
    $alert = $model->getById($alertId);
    
    if (!$alert) {
        Response::error('Price alert not found', 404);
        return;
    }
    
    $result = $model->addReaction($alertId, $authUser['user_id'], $type);
    
    if ($result) {
        $updated = $model->getById($alertId);
        if ($updated) {
            WebSocketPublisher::priceAlertUpdated($updated);
        }
        Response::success(['price_alert' => $updated], 'Reaction added successfully');
    } else {
        Response::error('Failed to add reaction', 500);
    }
}

/**
 * Remove reaction from price alert
 */
function removeReaction($alertId, $authUser) {
    // Check if user is blocked
    if (isUserBlocked($authUser['user_id'])) {
        Response::error('Your account has been blocked. You cannot interact with price alerts.', 403);
        return;
    }
    
    $model = new PriceAlertModel();
    $result = $model->removeReaction($alertId, $authUser['user_id']);
    
    if ($result) {
        $updated = $model->getById($alertId);
        if ($updated) {
            WebSocketPublisher::priceAlertUpdated($updated);
        }
        Response::success(['price_alert' => $updated], 'Reaction removed successfully');
    } else {
        Response::error('Failed to remove reaction', 500);
    }
}

/**
 * Push real-time + FCM when a new price/ride alert is created.
 */
function publishPriceAlertCreated(array $alert, array $creator) {
    WebSocketPublisher::priceAlertNew($alert);
    notifyPriceAlertRecipients($alert, $creator);
}

function notifyPriceAlertRecipients(array $alert, array $creator) {
    notifyPriceAlertWebSocket($alert, $creator);
    notifyPriceAlertFcm($alert, $creator);
}

function priceAlertNotificationContent(array $alert, array $creator) {
    $creatorName = $creator['display_name'] ?? 'Driver';
    $title = 'New ride alert';
    $body = $creatorName . ': ' . $alert['pickup'] . ' → ' . $alert['dropoff'] . ' $' . $alert['price'];
    $data = [
        'type' => 'ride_alert',
        'alert_id' => (string)$alert['id'],
        'pickup' => $alert['pickup'],
        'dropoff' => $alert['dropoff'],
        'price' => (string)$alert['price'],
        // Legacy / feed channel alias
        'price_alert' => '1',
    ];
    return [$title, $body, $data];
}

function notifyPriceAlertWebSocket(array $alert, array $creator) {
    [$title, $body, $data] = priceAlertNotificationContent($alert, $creator);

    $userModel = new UserModel();
    $users = $userModel->getAllUsers(2000);

    foreach ($users as $user) {
        if ($user['user_id'] === $creator['user_id']) {
            continue;
        }
        WebSocketPublisher::notification(
            $title,
            $body,
            $data,
            'ride_alert',
            $user['user_id']
        );
    }
}

function notifyPriceAlertFcm(array $alert, array $creator) {
    if (!function_exists('sendFCMNotification')) {
        require_once __DIR__ . '/../includes/FCMHelper.php';
    }

    if (!isFirebaseConfigured()) {
        error_log('Ride alert FCM skipped: Firebase not configured. Add FIREBASE_SERVICE_ACCOUNT_PATH to .env');
        return;
    }

    [$title, $body, $data] = priceAlertNotificationContent($alert, $creator);

    $userModel = new UserModel();
    $users = $userModel->getAllUsers(2000);

    $sent = 0;
    $failed = 0;
    $skipped = 0;

    foreach ($users as $user) {
        if ($user['user_id'] === $creator['user_id']) {
            continue;
        }
        if (empty($user['fcm_token'])) {
            $skipped++;
            continue;
        }
        if (sendFCMNotification($user['user_id'], $title, $body, $data, ['channel_id' => 'ride_alerts'])) {
            $sent++;
        } else {
            $failed++;
        }
    }

    error_log("Ride alert FCM: sent=$sent failed=$failed skipped_no_token=$skipped alert_id={$alert['id']}");
}

