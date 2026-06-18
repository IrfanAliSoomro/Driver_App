<?php

require_once __DIR__ . '/JWT.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Response.php';

class Auth {
    private $db;
    private $config;

    public function __construct() {
        $this->config = require __DIR__ . '/../config/config.php';
        $this->db = Database::getInstance();
    }

    public function validateToken() {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;
        
        // Log for debugging
        error_log('Auth headers: ' . json_encode($headers));
        
        if (!$authHeader) {
            error_log('No authorization header found');
            Response::unauthorized('No authorization header provided');
        }
        
        if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            error_log('Invalid auth header format: ' . $authHeader);
            Response::unauthorized('Invalid authorization header format');
        }
        
        $token = $matches[1];
        error_log('Token received: ' . substr($token, 0, 20) . '...');
        
        $payload = JWT::decode($token);
        
        if (!$payload) {
            error_log('Token decode failed');
            Response::unauthorized('Invalid or expired token');
        }
        
        error_log('Token payload: ' . json_encode($payload));
        
        return $payload;
    }

    public function requireAuth() {
        return $this->validateToken();
    }

    public function generateToken($userId, $email) {
        $payload = [
            'user_id' => $userId,
            'email' => $email,
        ];
        
        return JWT::encode($payload);
    }

    public function verifyGoogleToken($idToken) {
        $googleClientId = $this->config['google']['client_id'];
        
        // Verify Google ID token
        $url = 'https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken);
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode !== 200) {
            throw new Exception('Invalid Google token');
        }
        
        $tokenInfo = json_decode($response, true);
        
        if (!$tokenInfo || !isset($tokenInfo['email'])) {
            throw new Exception('Invalid token response');
        }
        
        // Optionally verify audience (client ID)
        if (isset($tokenInfo['aud']) && $googleClientId && $tokenInfo['aud'] !== $googleClientId) {
            throw new Exception('Token audience mismatch');
        }
        
        return $tokenInfo;
    }
}

