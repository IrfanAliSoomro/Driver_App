<?php

require_once __DIR__ . '/../includes/Database.php';

class UserModel {
    private $db;
    private $table = 'users';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create or update user
     */
    public function createOrUpdate($data) {
        try {
            $sql = "INSERT INTO {$this->table} 
                    (user_id, email, display_name, photo_url, fcm_token, last_sign_in, updated_at) 
                    VALUES (:user_id, :email, :display_name, :photo_url, :fcm_token, NOW(), NOW())
                    ON DUPLICATE KEY UPDATE 
                    email = VALUES(email),
                    display_name = VALUES(display_name),
                    photo_url = VALUES(photo_url),
                    fcm_token = VALUES(fcm_token),
                    last_sign_in = NOW(),
                    updated_at = NOW()";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':user_id' => $data['user_id'],
                ':email' => $data['email'],
                ':display_name' => $data['display_name'] ?? '',
                ':photo_url' => $data['photo_url'] ?? '',
                ':fcm_token' => $data['fcm_token'] ?? null
            ]);
            
            return true;
        } catch (PDOException $e) {
            error_log("Error creating/updating user: " . $e->getMessage());
            // Return error message for debugging
            throw new Exception("Database error: " . $e->getMessage());
        }
    }

    /**
     * Get user by ID
     */
    public function getUserById($userId) {
        try {
            $sql = "SELECT * FROM {$this->table} WHERE user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':user_id' => $userId]);
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching user: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get user by email
     */
    public function getUserByEmail($email) {
        try {
            $sql = "SELECT * FROM {$this->table} WHERE email = :email";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':email' => $email]);
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching user: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Update user location
     */
    public function updateLocation($userId, $latitude, $longitude) {
        try {
            $sql = "UPDATE {$this->table} 
                    SET latitude = :latitude, 
                        longitude = :longitude, 
                        location_updated_at = NOW() 
                    WHERE user_id = :user_id";
            
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                ':user_id' => $userId,
                ':latitude' => $latitude,
                ':longitude' => $longitude
            ]);
        } catch (PDOException $e) {
            error_log("Error updating location: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Update FCM token
     */
    public function updateFCMToken($userId, $fcmToken) {
        try {
            $sql = "UPDATE {$this->table} SET fcm_token = :fcm_token WHERE user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                ':user_id' => $userId,
                ':fcm_token' => $fcmToken
            ]);
        } catch (PDOException $e) {
            error_log("Error updating FCM token: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get all active users (last 24 hours)
     */
    public function getActiveUsers($limit = 100) {
        try {
            $sql = "SELECT user_id, email, display_name, photo_url, fcm_token, latitude, longitude, 
                           location_updated_at, last_sign_in 
                    FROM {$this->table} 
                    WHERE last_sign_in >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    ORDER BY last_sign_in DESC 
                    LIMIT :limit";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching active users: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get all users (no time restriction)
     */
    public function getAllUsers($limit = 100) {
        try {
            $sql = "SELECT user_id, email, display_name, photo_url, fcm_token, latitude, longitude, 
                           location_updated_at, last_sign_in, created_at
                    FROM {$this->table} 
                    ORDER BY last_sign_in DESC, created_at DESC
                    LIMIT :limit";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching all users: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Check if user is blocked
     */
    public function isBlocked($userId) {
        try {
            $sql = "SELECT COUNT(*) as count FROM blocked_drivers WHERE user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':user_id' => $userId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['count'] > 0;
        } catch (PDOException $e) {
            error_log("Error checking blocked status: " . $e->getMessage());
            return false;
        }
    }
}

