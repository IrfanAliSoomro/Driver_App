<?php
/**
 * Flight Data Endpoints
 * GET /api/flights - Get all flights
 * GET /api/flights/{id} - Get flight by ID
 * GET /api/flights/search - Search flights
 * POST /api/flights - Create/update flight data (admin only)
 * DELETE /api/flights/old - Delete old flights (admin only)
 */

require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../models/FlightModel.php';
require_once __DIR__ . '/../models/AdminModel.php';

$requestMethod = $_SERVER['REQUEST_METHOD'];
$auth = new Auth();

// Get path segments
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = explode('/', trim($path, '/'));

$flightIdOrAction = $segments[2] ?? null;

switch ($requestMethod) {
    case 'GET':
        if ($flightIdOrAction === 'search') {
            searchFlights();
        } elseif ($flightIdOrAction) {
            getFlight($flightIdOrAction);
        } else {
            getFlights();
        }
        break;
        
    case 'POST':
        $authUser = $auth->requireAuth();
        createOrUpdateFlight($authUser);
        break;
        
    case 'DELETE':
        $authUser = $auth->requireAuth();
        if ($flightIdOrAction === 'old') {
            deleteOldFlights($authUser);
        } else {
            Response::error('Invalid action', 404);
        }
        break;
        
    default:
        Response::error('Method not allowed', 405);
}

/**
 * Get all flights
 */
function getFlights() {
    $isArrival = isset($_GET['is_arrival']) ? (bool)$_GET['is_arrival'] : null;
    $limit = $_GET['limit'] ?? 100;
    
    $model = new FlightModel();
    $flights = $model->getAll($isArrival, $limit);
    
    Response::success(['flights' => $flights]);
}

/**
 * Get flight by ID
 */
function getFlight($flightId) {
    $model = new FlightModel();
    $flight = $model->getById($flightId);
    
    if (!$flight) {
        Response::error('Flight not found', 404);
        return;
    }
    
    Response::success(['flight' => $flight]);
}

/**
 * Search flights
 */
function searchFlights() {
    $query = $_GET['q'] ?? '';
    $limit = $_GET['limit'] ?? 50;
    
    if (empty($query)) {
        Response::error('Search query is required', 400);
        return;
    }
    
    $model = new FlightModel();
    $flights = $model->search($query, $limit);
    
    Response::success(['flights' => $flights]);
}

/**
 * Create or update flight data (admin only)
 */
function createOrUpdateFlight($authUser) {
    // Check if user is admin
    $adminModel = new AdminModel();
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $required = ['id', 'airline', 'flight_number', 'destination', 'scheduled_time', 'status', 'gate', 'airline_code', 'is_arrival'];
    $missing = Validator::required($data, $required);
    if (!empty($missing)) {
        Response::error('Missing required fields: ' . implode(', ', $missing), 400);
        return;
    }
    
    $model = new FlightModel();
    $result = $model->createOrUpdate($data);
    
    if ($result) {
        $flight = $model->getById($data['id']);
        Response::success(['flight' => $flight], 'Flight data saved successfully', 201);
    } else {
        Response::error('Failed to save flight data', 500);
    }
}

/**
 * Delete old flights (admin only)
 */
function deleteOldFlights($authUser) {
    // Check if user is admin
    $adminModel = new AdminModel();
    if (!$adminModel->isAdmin($authUser['user_id'])) {
        Response::error('Admin access required', 403);
        return;
    }
    
    $hours = $_GET['hours'] ?? 24;
    
    $model = new FlightModel();
    $count = $model->deleteOld($hours);
    
    Response::success([
        'deleted_count' => $count
    ], "Deleted {$count} old flights");
}

