<?php

/**
 * Middleware Class for Request Processing
 */
class Middleware {
    
    /**
     * Rate limiting middleware
     */
    public static function rateLimit($maxRequests = 100, $perMinutes = 1) {
        $ip = $_SERVER['REMOTE_ADDR'];
        $cacheKey = "rate_limit_" . md5($ip);
        
        // Simple file-based cache (in production, use Redis or Memcached)
        $cacheFile = sys_get_temp_dir() . "/$cacheKey.txt";
        
        $now = time();
        $requests = [];
        
        if (file_exists($cacheFile)) {
            $data = file_get_contents($cacheFile);
            $requests = json_decode($data, true) ?: [];
        }
        
        // Remove old requests
        $cutoff = $now - ($perMinutes * 60);
        $requests = array_filter($requests, function($timestamp) use ($cutoff) {
            return $timestamp > $cutoff;
        });
        
        if (count($requests) >= $maxRequests) {
            http_response_code(429);
            echo json_encode([
                'success' => false,
                'message' => 'Too many requests. Please try again later.',
                'code' => 429
            ]);
            exit();
        }
        
        // Add current request
        $requests[] = $now;
        file_put_contents($cacheFile, json_encode($requests));
    }
    
    /**
     * Request logging middleware
     */
    public static function logRequest() {
        $logData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'method' => $_SERVER['REQUEST_METHOD'],
            'uri' => $_SERVER['REQUEST_URI'],
            'ip' => $_SERVER['REMOTE_ADDR'],
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? ''
        ];
        
        $logFile = __DIR__ . '/../logs/requests.log';
        $logDir = dirname($logFile);
        
        if (!file_exists($logDir)) {
            mkdir($logDir, 0755, true);
        }
        
        file_put_contents(
            $logFile,
            json_encode($logData) . "\n",
            FILE_APPEND
        );
    }
    
    /**
     * Check if user is blocked
     */
    public static function checkBlocked($userId) {
        require_once __DIR__ . '/../models/UserModel.php';
        
        $userModel = new UserModel();
        if ($userModel->isBlocked($userId)) {
            http_response_code(403);
            echo json_encode([
                'success' => false,
                'message' => 'Your account has been blocked. Please contact support.',
                'code' => 403
            ]);
            exit();
        }
    }
    
    /**
     * Sanitize input data
     */
    public static function sanitizeInput(&$data) {
        if (is_array($data)) {
            foreach ($data as $key => &$value) {
                if (is_string($value)) {
                    $value = htmlspecialchars(strip_tags(trim($value)), ENT_QUOTES, 'UTF-8');
                } elseif (is_array($value)) {
                    self::sanitizeInput($value);
                }
            }
        }
    }
}

