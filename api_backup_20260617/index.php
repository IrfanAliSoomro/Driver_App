<?php
/**
 * Main API Router
 * Routes all API requests to appropriate endpoints
 */

require_once __DIR__ . '/includes/cors.php';

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get request URI and method
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Remove query string and get path
$path = parse_url($requestUri, PHP_URL_PATH);
$path = str_replace('/api2/', '', $path);
$path = trim($path, '/');

// Split path into segments
$segments = explode('/', $path);
$endpoint = $segments[0] ?? '';
// /api/chat/... → route to chat.php (document root above api folder)
if ($endpoint === 'api' && !empty($segments[1])) {
    $endpoint = $segments[1];
} elseif ($endpoint === 'api2' && !empty($segments[1])) {
    $endpoint = $segments[1];
}

// Debug logging
error_log('Index.php - Request URI: ' . $requestUri);
error_log('Index.php - Cleaned path: ' . $path);
error_log('Index.php - Endpoint: ' . $endpoint);

// Route to appropriate endpoint
$endpointFile = __DIR__ . "/endpoints/{$endpoint}.php";

error_log('Index.php - Looking for file: ' . $endpointFile);
error_log('Index.php - File exists: ' . (file_exists($endpointFile) ? 'YES' : 'NO'));

if (file_exists($endpointFile)) {
    require_once $endpointFile;
} else {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Endpoint not found',
        'endpoint' => $endpoint,
        'debug' => [
            'request_uri' => $requestUri,
            'cleaned_path' => $path,
            'segments' => $segments,
            'looking_for' => $endpointFile
        ]
    ]);
}

