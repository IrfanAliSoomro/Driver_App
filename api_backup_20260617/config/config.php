<?php

require_once __DIR__ . '/../includes/FirebaseConfig.php';

if (file_exists(__DIR__ . '/../.env')) {
    $lines = file(__DIR__ . '/../.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos($line, '=') !== false && strpos(trim($line), '#') !== 0) {
            [$key, $value] = explode('=', $line, 2);
            $_ENV[trim($key)] = trim($value);
            putenv(trim($key) . '=' . trim($value));
        }
    }
}

return [
    'timezone' => $_ENV['APP_TIMEZONE'] ?? getenv('APP_TIMEZONE') ?: 'UTC',
    'debug' => ($_ENV['APP_DEBUG'] ?? getenv('APP_DEBUG')) === '1',
    'db' => [
        'host' => $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: 'localhost',
        'port' => $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: '3306',
        'database' => $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?: 'aladgxlf_db2',
        'username' => $_ENV['DB_USER'] ?? getenv('DB_USER') ?: 'aladgxlf_user',
        'password' => $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?: '',
        'charset' => 'utf8mb4',
    ],
    'firebase' => loadFirebaseConfig(),
    'google' => [
        'client_id' => $_ENV['GOOGLE_CLIENT_ID'] ?? getenv('GOOGLE_CLIENT_ID') ?: '',
        'client_secret' => $_ENV['GOOGLE_CLIENT_SECRET'] ?? getenv('GOOGLE_CLIENT_SECRET') ?: '',
    ],
    'jwt' => [
        'secret' => $_ENV['JWT_SECRET'] ?? getenv('JWT_SECRET') ?: 'change-this-secret-key',
        'expiration' => (int)($_ENV['JWT_EXPIRATION'] ?? getenv('JWT_EXPIRATION') ?: 86400),
    ],
    'api' => [
        'url' => $_ENV['API_URL'] ?? getenv('API_URL') ?: 'http://69.197.174.68:8080/api',
        'allowed_origins' => $_ENV['ALLOWED_ORIGINS'] ?? getenv('ALLOWED_ORIGINS') ?: '*',
    ],
    'websocket' => [
        'enabled' => ($_ENV['WS_ENABLED'] ?? getenv('WS_ENABLED') ?: '1') !== '0',
        'host' => $_ENV['WS_HOST'] ?? getenv('WS_HOST') ?: '127.0.0.1',
        'port' => (int)($_ENV['WS_PORT'] ?? getenv('WS_PORT') ?: 8081),
        'internal_url' => $_ENV['WS_INTERNAL_URL'] ?? getenv('WS_INTERNAL_URL') ?: 'http://127.0.0.1:8081',
        'public_url' => $_ENV['WS_PUBLIC_URL'] ?? getenv('WS_PUBLIC_URL') ?: 'ws://69.197.174.68:8081',
        'secret' => $_ENV['WS_SECRET'] ?? getenv('WS_SECRET') ?: 'change-this-ws-secret',
    ],
];
