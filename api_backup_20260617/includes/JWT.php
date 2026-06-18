<?php

class JWT {
    private static $secret = null;
    private static $expiration = 86400;

    private static function getSecret() {
        if (self::$secret === null) {
            $config = require __DIR__ . '/../config/config.php';
            self::$secret = $config['jwt']['secret'];
            self::$expiration = $config['jwt']['expiration'];
        }
        return self::$secret;
    }

    public static function encode($payload, $expiration = null) {
        $secret = self::getSecret();
        if ($expiration === null) {
            $expiration = self::$expiration;
        }
        
        $payload['iat'] = time();
        $payload['exp'] = time() + $expiration;
        
        $header = self::base64UrlEncode(json_encode(['typ' => 'JWT', 'alg' => 'HS256']));
        $encodedPayload = self::base64UrlEncode(json_encode($payload));
        $signature = self::base64UrlEncode(hash_hmac('sha256', "$header.$encodedPayload", $secret, true));
        
        return "$header.$encodedPayload.$signature";
    }

    public static function decode($token) {
        $secret = self::getSecret();
        $parts = explode('.', $token);
        
        if (count($parts) !== 3) {
            error_log('JWT decode error: Invalid token format (parts: ' . count($parts) . ')');
            return false;
        }
        
        list($header, $payload, $signature) = $parts;
        
        $validSignature = self::base64UrlEncode(
            hash_hmac('sha256', "$header.$payload", $secret, true)
        );
        
        if ($signature !== $validSignature) {
            error_log('JWT decode error: Invalid signature');
            return false;
        }
        
        $decodedPayload = json_decode(self::base64UrlDecode($payload), true);
        
        if (!isset($decodedPayload['exp'])) {
            error_log('JWT decode error: Missing expiration');
            return false;
        }
        
        if ($decodedPayload['exp'] < time()) {
            error_log('JWT decode error: Token expired (exp: ' . $decodedPayload['exp'] . ', now: ' . time() . ')');
            return false;
        }
        
        return $decodedPayload;
    }

    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }
}

