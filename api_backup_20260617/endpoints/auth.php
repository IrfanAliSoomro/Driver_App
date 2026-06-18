<?php
/**
 * Authentication Endpoints
 * POST /api/auth/google - Google sign in
 * POST /api/auth/verify - Verify JWT token
 * POST /api/auth/refresh - Refresh JWT token
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/JWT.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../models/UserModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];

// Get sub-path
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));
$action = $segments[2] ?? '';

switch ($action) {
    case 'google':
        if ($requestMethod === 'POST') {
            handleGoogleAuth();
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'verify':
        if ($requestMethod === 'POST') {
            verifyToken();
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    case 'refresh':
        if ($requestMethod === 'POST') {
            refreshToken();
        } else {
            Response::error('Method not allowed', 405);
        }
        break;
        
    default:
        Response::error('Invalid auth endpoint', 404);
}

/**
 * Handle Google authentication
 */
function handleGoogleAuth() {
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    $required = ['id_token', 'user_id', 'email'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    // Verify Google ID token (simplified - in production, verify with Google)
    // For now, we trust the client's token
    
    $userModel = new UserModel();
    
    // Create or update user
    $userData = [
        'user_id' => $data['user_id'],
        'email' => $data['email'],
        'display_name' => $data['display_name'] ?? '',
        'photo_url' => $data['photo_url'] ?? '',
        'fcm_token' => $data['fcm_token'] ?? null
    ];
    
    try {
        $result = $userModel->createOrUpdate($userData);
        
        if (!$result) {
            Response::error('Failed to create/update user', 500);
            return;
        }
    } catch (Exception $e) {
        Response::error('Failed to create/update user: ' . $e->getMessage(), 500);
        return;
    }
    
    // Generate JWT token
    $payload = [
        'user_id' => $data['user_id'],
        'email' => $data['email']
    ];
    
    $token = JWT::encode($payload);
    
    // Get user data and append access-control state used by clients.
    $user = $userModel->getUserById($data['user_id']);
    if (!$user) {
        $user = [
            'user_id' => $data['user_id'],
            'email' => $data['email'],
            'display_name' => $data['display_name'] ?? '',
            'photo_url' => $data['photo_url'] ?? '',
            'fcm_token' => $data['fcm_token'] ?? null
        ];
    }

    $blocked = (bool)$userModel->isBlocked($data['user_id']);
    $user['blocked'] = $blocked;
    
    Response::success([
        'token' => $token,
        'user' => $user,
        'blocked' => $blocked
    ], 'Authentication successful');
}

/**
 * Verify JWT token
 */
function verifyToken() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    
    if (empty($authHeader)) {
        Response::error('Authorization header missing', 401);
        return;
    }
    
    $token = str_replace('Bearer ', '', $authHeader);
    $payload = JWT::decode($token);
    
    if (!$payload) {
        Response::error('Invalid or expired token', 401);
        return;
    }
    
    Response::success([
        'user_id' => $payload['user_id'],
        'email' => $payload['email']
    ], 'Token is valid');
}

/**
 * Refresh JWT token
 */
function refreshToken() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    
    if (empty($authHeader)) {
        Response::error('Authorization header missing', 401);
        return;
    }
    
    $token = str_replace('Bearer ', '', $authHeader);
    $payload = JWT::decode($token);
    
    if (!$payload) {
        Response::error('Invalid or expired token', 401);
        return;
    }
    
    // Generate new token
    $newToken = JWT::encode([
        'user_id' => $payload['user_id'],
        'email' => $payload['email']
    ]);
    
    Response::success([
        'token' => $newToken
    ], 'Token refreshed successfully');
}

