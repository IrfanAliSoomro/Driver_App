<?php
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Auth.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Validator.php';
require_once __DIR__ . '/../includes/ActiveUsersHelper.php';

header('Content-Type: application/json');

// Enable CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$requestUri = $_SERVER['REQUEST_URI'];
$path = activeUsersNormalizePath($requestUri);

// Route: /active-users
if ($path === 'active-users' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    getActiveUsersCount();
}
// Route: /active-users/parking-lots
elseif ($path === 'active-users/parking-lots' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    getParkingLots();
}
// Route: /active-users/increment
elseif ($path === 'active-users/increment' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    incrementActiveUserCount();
}
// Route: /active-users/decrement
elseif ($path === 'active-users/decrement' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    decrementActiveUserCount();
}
// Route: /active-users/{user_id} (DELETE only — not parking-lots/increment/decrement)
elseif (preg_match('/^active-users\/([^\/]+)$/', $path, $matches)
    && $_SERVER['REQUEST_METHOD'] === 'DELETE'
    && !in_array($matches[1], ['parking-lots', 'increment', 'decrement'], true)) {
    $userId = $matches[1];
    removeUserFromAllLocations($userId);
}
else {
    Response::error('Endpoint not found', 404);
}

/**
 * Normalize path for /api/... and /api2/... deployments.
 * e.g. /api/active-users/parking-lots → active-users/parking-lots
 */
function activeUsersNormalizePath(string $requestUri): string {
    $path = parse_url($requestUri, PHP_URL_PATH) ?? '';
    $path = trim($path, '/');
    if (preg_match('#^api2?/(.+)$#', $path, $m)) {
        return $m[1];
    }
    return $path;
}

/**
 * Get parking lot configurations from database
 */
function getParkingLots() {
    try {
        $db = Database::getInstance();
        
        // Get all active parking lots from database
        $sql = "SELECT name, latitude, longitude, radius_meters FROM parking_lots WHERE is_active = TRUE ORDER BY name";
        $results = $db->fetchAll($sql);
        
        if (empty($results)) {
            Response::error('No parking lots found', 404);
            return;
        }
        
        // Format the response
        $parkingLots = [];
        foreach ($results as $row) {
            $parkingLots[] = [
                'name' => $row['name'],
                'latitude' => (float)$row['latitude'],
                'longitude' => (float)$row['longitude'],
                'radius_meters' => (int)$row['radius_meters']
            ];
        }
        
        Response::success($parkingLots, 'Parking lots retrieved successfully');
        
    } catch (Exception $e) {
        error_log("Error getting parking lots: " . $e->getMessage());
        Response::error('Failed to get parking lots: ' . $e->getMessage(), 500);
    }
}

/**
 * Get active users count for all parking lots
 */
function getActiveUsersCount() {
    try {
        $db = Database::getInstance();
        
        // Get active users count using the view
        $sql = "SELECT location_name, active_count FROM active_users_count ORDER BY location_name";
        $results = $db->fetchAll($sql);
        
        // Format the response
        $activeUsers = [
            'MidwayLot' => 0,
            'OhareAlphaLot' => 0,
            'OhareDeltaLot' => 0
        ];
        
        foreach ($results as $row) {
            $activeUsers[$row['location_name']] = (int)$row['active_count'];
        }
        
        Response::success($activeUsers, 'Active users count retrieved successfully');
        
    } catch (Exception $e) {
        error_log("Error getting active users count: " . $e->getMessage());
        Response::error('Failed to get active users count: ' . $e->getMessage(), 500);
    }
}

/**
 * Increment active user count for a parking lot
 */
function incrementActiveUserCount() {
    try {
        $auth = new Auth();
        $payload = $auth->requireAuth();
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Validate required fields
        $required = ['parking_lot'];
        $missing = Validator::required($data, $required);
        if (!empty($missing)) {
            // New clients send location_name (same value as parking_lot name).
            if (!empty($data['location_name'])) {
                $data['parking_lot'] = $data['location_name'];
            } else {
                Response::error('Missing required fields: ' . implode(', ', $missing), 400);
                return;
            }
        }
        
        $userId = $payload['user_id'];
        $parkingLot = $data['parking_lot'] ?? $data['location_name'];
        
        $db = Database::getInstance();
        
        // Check if user is already counted in this parking lot
        $sql = "SELECT id FROM active_users WHERE user_id = :user_id AND location_name = :location_name";
        $existing = $db->fetchOne($sql, [
            ':user_id' => $userId,
            ':location_name' => $parkingLot
        ]);
        
        if ($existing) {
            // Update last_seen timestamp for existing user
            $sql = "UPDATE active_users SET last_seen = CURRENT_TIMESTAMP WHERE user_id = :user_id AND location_name = :location_name";
            $db->query($sql, [
                ':user_id' => $userId,
                ':location_name' => $parkingLot
            ]);
            
            Response::success(['count' => getCurrentCount($parkingLot)], 'User already counted in this parking lot');
            return;
        }
        
        // Add user to parking lot
        $sql = "INSERT INTO active_users (user_id, location_name, status) 
                VALUES (:user_id, :location_name, 'active')";
        
        $db->query($sql, [
            ':user_id' => $userId,
            ':location_name' => $parkingLot
        ]);
        
        $newCount = getCurrentCount($parkingLot);
        ActiveUsersHelper::publishCounts();
        
        Response::success([
            'count' => $newCount,
            'parking_lot' => $parkingLot
        ], 'User count incremented successfully');
        
    } catch (Exception $e) {
        error_log("Error incrementing active user count: " . $e->getMessage());
        Response::error('Failed to increment count: ' . $e->getMessage(), 500);
    }
}

/**
 * Decrement active user count for a parking lot
 */
function decrementActiveUserCount() {
    try {
        $auth = new Auth();
        $payload = $auth->requireAuth();
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Validate required fields
        $required = ['parking_lot'];
        $missing = Validator::required($data, $required);
        if (!empty($missing)) {
            // New clients send location_name (same value as parking_lot name).
            if (!empty($data['location_name'])) {
                $data['parking_lot'] = $data['location_name'];
            } else {
                Response::error('Missing required fields: ' . implode(', ', $missing), 400);
                return;
            }
        }
        
        $userId = $payload['user_id'];
        $parkingLot = $data['parking_lot'] ?? $data['location_name'];
        
        $db = Database::getInstance();
        
        // Remove user from parking lot
        $sql = "DELETE FROM active_users WHERE user_id = :user_id AND location_name = :location_name";
        $db->query($sql, [
            ':user_id' => $userId,
            ':location_name' => $parkingLot
        ]);
        
        $newCount = getCurrentCount($parkingLot);
        ActiveUsersHelper::publishCounts();
        
        Response::success([
            'count' => $newCount,
            'parking_lot' => $parkingLot
        ], 'User count decremented successfully');
        
    } catch (Exception $e) {
        error_log("Error decrementing active user count: " . $e->getMessage());
        Response::error('Failed to decrement count: ' . $e->getMessage(), 500);
    }
}

/**
 * Get current count for a specific parking lot
 */
function getCurrentCount($parkingLot) {
    $db = Database::getInstance();
    
    $sql = "SELECT COUNT(*) as count FROM active_users 
            WHERE location_name = :location_name 
            AND status = 'active' 
            AND last_seen > DATE_SUB(NOW(), INTERVAL 5 MINUTE)";
    
    $result = $db->fetchOne($sql, [':location_name' => $parkingLot]);
    return (int)$result['count'];
}

/**
 * Remove user from all locations (when they go offline)
 */
function removeUserFromAllLocations($userId) {
    try {
        $db = Database::getInstance();
        
        $sql = "DELETE FROM active_users WHERE user_id = :user_id";
        $db->query($sql, [':user_id' => $userId]);
        ActiveUsersHelper::publishCounts();
        
        Response::success(null, 'User removed from all locations');
        
    } catch (Exception $e) {
        error_log("Error removing user from locations: " . $e->getMessage());
        Response::error('Failed to remove user: ' . $e->getMessage(), 500);
    }
}
?>
