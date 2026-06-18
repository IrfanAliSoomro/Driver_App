<?php

require_once __DIR__ . '/../includes/Database.php';

class AdminModel {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Check if user is admin
     */
    public function isAdmin($userId) {
        try {
            $sql = "SELECT COUNT(*) as count FROM admin_users WHERE user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':user_id' => $userId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['count'] > 0;
        } catch (PDOException $e) {
            error_log("Error checking admin status: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get all admin user IDs
     */
    public function getAllAdmins() {
        try {
            $sql = "SELECT user_id FROM admin_users";
            $stmt = $this->db->query($sql);
            $admins = $stmt->fetchAll(PDO::FETCH_COLUMN);
            return $admins;
        } catch (PDOException $e) {
            error_log("Error fetching admins: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Add admin user
     */
    public function addAdmin($userId) {
        try {
            $sql = "INSERT IGNORE INTO admin_users (user_id, created_at) VALUES (:user_id, NOW())";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':user_id' => $userId]);
        } catch (PDOException $e) {
            error_log("Error adding admin: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Remove admin user
     */
    public function removeAdmin($userId) {
        try {
            $sql = "DELETE FROM admin_users WHERE user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':user_id' => $userId]);
        } catch (PDOException $e) {
            error_log("Error removing admin: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Block driver
     */
    public function blockDriver($userId, $reason = null) {
        try {
            // Ensure reason is not null
            $reason = $reason ?? 'Violation of community guidelines';
            
            // Use different parameter names for INSERT and UPDATE to avoid conflict
            $sql = "INSERT INTO blocked_drivers (user_id, reason, blocked_at) 
                    VALUES (:user_id, :reason1, NOW())
                    ON DUPLICATE KEY UPDATE reason = :reason2, blocked_at = NOW()";
            $stmt = $this->db->prepare($sql);
            $success = $stmt->execute([
                ':user_id' => $userId,
                ':reason1' => $reason,
                ':reason2' => $reason
            ]);
            
            if (!$success) {
                error_log("Failed to execute block driver query for user: $userId");
            }
            
            return $success;
        } catch (PDOException $e) {
            error_log("Error blocking driver: " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            return false;
        }
    }

    /**
     * Unblock driver
     */
    public function unblockDriver($userId) {
        try {
            $sql = "DELETE FROM blocked_drivers WHERE user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':user_id' => $userId]);
        } catch (PDOException $e) {
            error_log("Error unblocking driver: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get all blocked drivers
     */
    public function getBlockedDrivers() {
        try {
            $sql = "SELECT bd.*, u.email, u.display_name, u.photo_url
                    FROM blocked_drivers bd
                    LEFT JOIN users u ON bd.user_id = u.user_id
                    ORDER BY bd.blocked_at DESC";
            $stmt = $this->db->query($sql);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching blocked drivers: " . $e->getMessage());
            return [];
        }
    }
}

