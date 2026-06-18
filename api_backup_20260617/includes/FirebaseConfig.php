<?php

/**
 * Load Firebase credentials from service-account JSON path or .env variables.
 */
function loadFirebaseConfig() {
    $projectId = trim($_ENV['FIREBASE_PROJECT_ID'] ?? getenv('FIREBASE_PROJECT_ID') ?: '');
    $serverKey = trim($_ENV['FIREBASE_SERVER_KEY'] ?? getenv('FIREBASE_SERVER_KEY') ?: '');
    $serviceAccount = [
        'client_email' => trim($_ENV['FIREBASE_CLIENT_EMAIL'] ?? getenv('FIREBASE_CLIENT_EMAIL') ?: ''),
        'private_key' => '',
        'project_id' => $projectId,
    ];

    $privateKey = $_ENV['FIREBASE_PRIVATE_KEY'] ?? getenv('FIREBASE_PRIVATE_KEY') ?: '';
    if ($privateKey !== '') {
        $serviceAccount['private_key'] = str_replace('\\n', "\n", $privateKey);
    }

    $jsonPath = trim($_ENV['FIREBASE_SERVICE_ACCOUNT_PATH'] ?? getenv('FIREBASE_SERVICE_ACCOUNT_PATH') ?: '');
    if ($jsonPath !== '' && is_readable($jsonPath)) {
        $json = json_decode(file_get_contents($jsonPath), true);
        if (is_array($json)) {
            $serviceAccount['client_email'] = $json['client_email'] ?? $serviceAccount['client_email'];
            $serviceAccount['private_key'] = $json['private_key'] ?? $serviceAccount['private_key'];
            if (empty($projectId) && !empty($json['project_id'])) {
                $projectId = $json['project_id'];
                $serviceAccount['project_id'] = $projectId;
            }
        }
    }

    return [
        'project_id' => $projectId,
        'server_key' => $serverKey,
        'service_account' => $serviceAccount,
    ];
}

function isFirebaseConfigured() {
    $config = loadFirebaseConfig();
    $sa = $config['service_account'] ?? [];
    $hasServiceAccount = !empty($sa['client_email']) && !empty($sa['private_key']) && !empty($config['project_id']);
    $hasLegacyKey = !empty($config['server_key']) && $config['server_key'] !== 'your-server-key';
    return $hasServiceAccount || $hasLegacyKey;
}
