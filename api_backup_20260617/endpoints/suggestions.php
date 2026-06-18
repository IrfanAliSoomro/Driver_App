<?php
/**
 * Suggestions Endpoints
 * GET /api/suggestions - Get all suggestions
 * GET /api/suggestions/{id} - Get suggestion by ID
 * POST /api/suggestions - Create new suggestion
 * PUT /api/suggestions/{id} - Update suggestion (admin only)
 * DELETE /api/suggestions/{id} - Delete suggestion (admin only)
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../models/SuggestionModel.php';
require_once __DIR__ . '/../models/AdminModel.php';
require_once __DIR__ . '/../includes/FCMHelper.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$suggestionId = $segments[2] ?? null;

switch ($requestMethod) {
    case 'GET':
        if ($suggestionId) {
            getSuggestion($suggestionId);
        } else {
            getSuggestions();
        }
        break;
        
    case 'POST':
        $authUser = $auth->requireAuth();
        createSuggestion($authUser);
        break;
        
    case 'PUT':
        $authUser = $auth->requireAuth();
        updateSuggestion($suggestionId, $authUser);
        break;
        
    case 'DELETE':
        $authUser = $auth->requireAuth();
        deleteSuggestion($suggestionId, $authUser);
        break;
        
    default:
        Response::error('Method not allowed', 405);
}

/**
 * Get all suggestions
 */
function getSuggestions() {
    $status = $_GET['status'] ?? null;
    $limit = $_GET['limit'] ?? 50;
    $offset = $_GET['offset'] ?? 0;
    
    $model = new SuggestionModel();
    $suggestions = $model->getAll($status, $limit, $offset);
    
    Response::success(['suggestions' => $suggestions]);
}

/**
 * Get suggestion by ID
 */
function getSuggestion($suggestionId) {
    $model = new SuggestionModel();
    $suggestion = $model->getById($suggestionId);
    
    if (!$suggestion) {
        Response::error('Suggestion not found', 404);
        return;
    }
    
    Response::success(['suggestion' => $suggestion]);
}

/**
 * Create new suggestion
 */
function createSuggestion($authUser) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    $required = ['title', 'description', 'driver_name'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    $data['user_id'] = $authUser['user_id'];
    
    $model = new SuggestionModel();
    $suggestionId = $model->create($data);
    
    if ($suggestionId) {
        // Send notification to all admins
        notifyAdminsNewSuggestion($suggestionId, $data['driver_name'], $data['title']);
        
        $suggestion = $model->getById($suggestionId);
        Response::success(['suggestion' => $suggestion], 'Suggestion created successfully', 201);
    } else {
        Response::error('Failed to create suggestion', 500);
    }
}

/**
 * Update suggestion (admin only)
 */
function updateSuggestion($suggestionId, $authUser) {
    if (!$suggestionId) {
        Response::error('Suggestion ID is required', 400);
        return;
    }
    
    // Check if user is admin
    $adminModel = new AdminModel();
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (empty($data['status'])) {
        Response::error('Status is required', 400);
        return;
    }
    
    if (!in_array($data['status'], ['pending', 'reviewed', 'implemented'])) {
        Response::error('Invalid status', 400);
        return;
    }
    
    $model = new SuggestionModel();
    $result = $model->updateStatus(
        $suggestionId,
        $data['status'],
        $data['admin_response'] ?? null
    );
    
    if ($result) {
        $updated = $model->getById($suggestionId);
        Response::success(['suggestion' => $updated], 'Suggestion updated successfully');
    } else {
        Response::error('Failed to update suggestion', 500);
    }
}

/**
 * Delete suggestion (admin only)
 */
function deleteSuggestion($suggestionId, $authUser) {
    if (!$suggestionId) {
        Response::error('Suggestion ID is required', 400);
        return;
    }
    
    // Check if user is admin
    $adminModel = new AdminModel();
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $model = new SuggestionModel();
    $result = $model->delete($suggestionId);
    
    if ($result) {
        Response::success(null, 'Suggestion deleted successfully');
    } else {
        Response::error('Failed to delete suggestion', 500);
    }
}

