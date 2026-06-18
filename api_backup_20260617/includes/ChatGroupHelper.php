<?php

/**
 * Chat group id from URL path (e.g. midway, ohare, ord-limo-lot).
 * Lowercase letters, digits, hyphens; must not start/end with a hyphen; max 64 chars.
 */
class ChatGroupHelper {
    public static function isValidGroupSlug($group) {
        if ($group === null || $group === '') {
            return false;
        }
        if (strlen($group) > 64) {
            return false;
        }
        return (bool) preg_match('/^[a-z0-9]([a-z0-9\-]*[a-z0-9])?$/', $group);
    }
}
