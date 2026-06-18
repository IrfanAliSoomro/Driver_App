<?php

/**
 * Input Validation Class
 */
class Validator {
    
    /**
     * Validate required fields
     */
    public static function required($data, $fields) {
        $missing = [];
        foreach ($fields as $field) {
            if (!isset($data[$field]) || trim($data[$field]) === '') {
                $missing[] = $field;
            }
        }
        return $missing;
    }
    
    /**
     * Validate email format
     */
    public static function email($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL);
    }
    
    /**
     * Sanitize string
     */
    public static function sanitizeString($string) {
        return htmlspecialchars(strip_tags(trim($string)));
    }

    /**
     * Plain chat / API text: trim and strip tags only (no HTML entities).
     * JSON responses and Flutter render as plain text; htmlspecialchars breaks apostrophes etc.
     */
    public static function sanitizeChatPlainText($string) {
        return strip_tags(trim((string) $string));
    }
    
    /**
     * Validate numeric value
     */
    public static function numeric($value) {
        return is_numeric($value);
    }
    
    /**
     * Validate minimum length
     */
    public static function minLength($value, $min) {
        return strlen($value) >= $min;
    }
    
    /**
     * Validate maximum length
     */
    public static function maxLength($value, $max) {
        return strlen($value) <= $max;
    }
    
    /**
     * Validate date format
     */
    public static function date($date, $format = 'Y-m-d H:i:s') {
        $d = DateTime::createFromFormat($format, $date);
        return $d && $d->format($format) === $date;
    }
}

