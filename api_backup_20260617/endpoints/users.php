<?php
/**
 * User Management Endpoints
 * GET /api/users - Get all users
 * GET /api/users/{id} - Get user by ID
 * PUT /api/users/{id}/location - Update user location
 * PUT /api/users/{id}/fcm - Update FCM token
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../models/UserModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

// Get path info
$userId = $segments[2] ?? null;
$action = $segments[3] ?? null;

switch ($requestMethod) {
    case 'GET':
        if ($userId) {
            getUser($userId);
        } else {
            getUsers();
        }
        break;
        
    case 'PUT':
        $authUser = $auth->requireAuth();
        if ($action === 'location') {
            updateLocation($userId, $authUser);
        } elseif ($action === 'fcm') {
            updateFCMToken($userId, $authUser);
        } else {
            Response::error('Invalid action', 404);
        }
        break;
        
    default:
        Response::error('Method not allowed', 405);
}

/**
 * Get all users (or only active users based on 'all' parameter)
 */
function getUsers() {
    $limit = $_GET['limit'] ?? 100;
    $all = isset($_GET['all']) && $_GET['all'] == '1';
    
    $userModel = new UserModel();
    
    // If 'all=1' parameter is present, get all users, otherwise get only active (last 24h)
    if ($all) {
        $users = $userModel->getAllUsers($limit);
    } else {
        $users = $userModel->getActiveUsers($limit);
    }
    
    Response::success(['users' => $users]);
}

/**
 * Get user by ID
 */
function getUser($userId) {
    $userModel = new UserModel();
    $user = $userModel->getUserById($userId);
    
    if (!$user) {
        Response::error('User not found', 404);
        return;
    }
    
    Response::success(['user' => $user]);
}

/**
 * Update user location
 */
function updateLocation($userId, $authUser) {
    // Users can only update their own location
    if ($userId !== $authUser['user_id']) {
        Response::error('Unauthorized', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $required = ['latitude', 'longitude'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    $userModel = new UserModel();
    $result = $userModel->updateLocation(
        $userId,
        $data['latitude'],
        $data['longitude']
    );
    
    if ($result) {
        Response::success(null, 'Location updated successfully');
    } else {
        Response::error('Failed to update location', 500);
    }
}

/**
 * Update FCM token
 */
function updateFCMToken($userId, $authUser) {
    // Users can only update their own FCM token
    if ($userId !== $authUser['user_id']) {
        Response::error('Unauthorized', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['fcm_token'])) {
        Response::error('FCM token is required', 400);
        return;
    }
    
    $userModel = new UserModel();
    $result = $userModel->updateFCMToken($userId, $data['fcm_token']);
    
    if ($result) {
        Response::success(null, 'FCM token updated successfully');
    } else {
        Response::error('Failed to update FCM token', 500);
    }
}

