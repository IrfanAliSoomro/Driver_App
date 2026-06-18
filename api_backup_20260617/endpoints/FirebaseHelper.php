<?php
/**
 * Firebase Helper Functions
 * This file contains Firebase-related utility functions
 */

/**
 * Generate Firebase Access Token using Service Account
 * This function creates a JWT token for Firebase authentication
 */
if (!function_exists('generateFirebaseAccessToken')) {
function generateFirebaseAccessToken() {
    $config = require __DIR__ . '/../config/config.php';
    $serviceAccount = $config['firebase']['service_account'];
    
    if (empty($serviceAccount['client_email']) || empty($serviceAccount['private_key'])) {
        error_log('Firebase service account credentials not configured');
        return false;
    }
    
    // JWT Header
    $header = json_encode([
        'typ' => 'JWT',
        'alg' => 'RS256'
    ]);
    
    // JWT Payload
    $now = time();
    $payload = json_encode([
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600, // 1 hour
        'iat' => $now
    ]);
    
    // Encode Header and Payload
    $base64Header = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64Payload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    
    // Create Signature
    $signature = '';
    $privateKey = $serviceAccount['private_key'];
    
    if (!openssl_sign($base64Header . '.' . $base64Payload, $signature, $privateKey, OPENSSL_ALGO_SHA256)) {
        error_log('Failed to create JWT signature');
        return false;
    }
    
    $base64Signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    // Create JWT
    $jwt = $base64Header . '.' . $base64Payload . '.' . $base64Signature;
    
    // Exchange JWT for Access Token
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/x-www-form-urlencoded'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        error_log('Failed to get access token: HTTP ' . $httpCode . ' - ' . $response);
        return false;
    }
    
    $data = json_decode($response, true);
    return $data['access_token'] ?? false;
}
}
