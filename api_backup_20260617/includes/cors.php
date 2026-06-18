<?php

$config = require __DIR__ . '/../config/config.php';
date_default_timezone_set($config['timezone'] ?? 'UTC');
$allowedOrigins = $config['api']['allowed_origins'];

// Handle CORS
if ($allowedOrigins === '*') {
    header('Access-Control-Allow-Origin: *');
} else {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $origins = explode(',', $allowedOrigins);
    
    if (in_array($origin, $origins)) {
        header('Access-Control-Allow-Origin: ' . $origin);
    }
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 3600');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

