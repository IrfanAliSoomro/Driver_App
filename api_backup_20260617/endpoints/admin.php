<?php
/**
 * Admin Endpoints
 * GET /api/admin/check - Check if user is admin
 * GET /api/admin/list - Get all admin user IDs
 * POST /api/admin/block - Block a driver
 * POST /api/admin/unblock - Unblock a driver
 * GET /api/admin/blocked - Get all blocked drivers
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../models/AdminModel.php';
require_once __DIR__ . '/../includes/FCMHelper.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$action = $segments[2] ?? '';

switch ($action) {
    case 'check':
        if ($requestMethod === 'GET') {
            $authUser = $auth->requireAuth();
            checkAdmin($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'list':
        if ($requestMethod === 'GET') {
            getAdminList();
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'block':
        if ($requestMethod === 'POST') {
            $authUser = $auth->requireAuth();
            blockDriver($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'unblock':
        if ($requestMethod === 'POST') {
            $authUser = $auth->requireAuth();
            unblockDriver($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'blocked':
        if ($requestMethod === 'GET') {
            $authUser = $auth->requireAuth();
            getBlockedDrivers($authUser);
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'add':
        if ($requestMethod === 'POST') {
            addAdmin();
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'remove':
        if ($requestMethod === 'DELETE') {
            removeAdmin();
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    default:
        Response::error('Invalid admin endpoint', 404);
}

/**
 * Check if current user is admin
 */
function checkAdmin($authUser) {
    $adminModel = new AdminModel();
    $isAdmin = $adminModel->isAdmin($authUser['user_id']);
    
    Response::success([
        'is_admin' => $isAdmin,
        'user_id' => $authUser['user_id']
    ]);
}

/**
 * Get list of all admin user IDs
 */
function getAdminList() {
    $adminModel = new AdminModel();
    $adminIds = $adminModel->getAllAdmins();
    
    Response::success([
        'admin_user_ids' => $adminIds
    ]);
}

/**
 * Block a driver (admin only)
 */
function blockDriver($authUser) {
    $adminModel = new AdminModel();
    
    // Check if user is admin
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['user_id'])) {
        Response::error('User ID is required', 400);
        return;
    }
    
    $userId = $data['user_id'];
    $reason = $data['reason'] ?? null;
    
    $result = $adminModel->blockDriver($userId, $reason);
    
    if ($result) {
        // Send notification to the blocked driver
        require_once __DIR__ . '/../includes/FCMHelper.php';
        notifyDriverBlocked($userId, $reason);
        
        Response::success(null, 'Driver blocked successfully');
    } else {
        Response::error('Failed to block driver', 500);
    }
}

/**
 * Unblock a driver (admin only)
 */
function unblockDriver($authUser) {
    $adminModel = new AdminModel();
    
    // Check if user is admin
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['user_id'])) {
        Response::error('User ID is required', 400);
        return;
    }
    
    $result = $adminModel->unblockDriver($data['user_id']);
    
    if ($result) {
        // Send notification to the unblocked driver
        require_once __DIR__ . '/../includes/FCMHelper.php';
        notifyDriverUnblocked($data['user_id']);
        
        Response::success(null, 'Driver unblocked successfully');
    } else {
        Response::error('Failed to unblock driver', 500);
    }
}

/**
 * Get all blocked drivers (admin only)
 */
function getBlockedDrivers($authUser) {
    $adminModel = new AdminModel();
    
    // Check if user is admin
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $blockedDrivers = $adminModel->getBlockedDrivers();
    
    Response::success([
        'blocked_drivers' => $blockedDrivers
    ]);
}

/**
 * Add admin user (requires auth token or direct database access)
 */
function addAdmin() {
    $adminModel = new AdminModel();
    
    // Get user_id from request
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['user_id'])) {
        Response::error('User ID is required', 400);
        return;
    }
    
    $userId = $data['user_id'];
    
    // Check if user exists in users table
    require_once __DIR__ . '/../includes/Database.php';
    $db = Database::getInstance()->getConnection();
    $stmt = $db->prepare("SELECT COUNT(*) as count FROM users WHERE user_id = :user_id");
    $stmt->execute([':user_id' => $userId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result['count'] == 0) {
        Response::error('User does not exist', 404);
        return;
    }
    
    // Add admin
    $result = $adminModel->addAdmin($userId);
    
    if ($result) {
        // Send notification to the newly promoted admin
        require_once __DIR__ . '/../includes/FCMHelper.php';
        notifyAdminPromotion($userId);
        
        Response::success(null, 'Admin user added successfully');
    } else {
        Response::error('Failed to add admin user', 500);
    }
}

/**
 * Remove admin user (requires auth token or direct database access)
 */
function removeAdmin() {
    $adminModel = new AdminModel();
    
    // Get user_id from request
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['user_id'])) {
        Response::error('User ID is required', 400);
        return;
    }
    
    $userId = $data['user_id'];
    
    // Remove admin
    $result = $adminModel->removeAdmin($userId);
    
    if ($result) {
        Response::success(null, 'Admin user removed successfully');
    } else {
        Response::error('Failed to remove admin user', 500);
    }
}


