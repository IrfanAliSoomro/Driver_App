<?php

require_once __DIR__ . '/../includes/Database.php';

class SuggestionModel {
    private $db;
    private $table = 'suggestions';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create a new suggestion
     */
    public function create($data) {
        try {
            $sql = "INSERT INTO {$this->table} 
                    (user_id, driver_name, title, description, status, created_at) 
                    VALUES (:user_id, :driver_name, :title, :description, 'pending', NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':user_id' => $data['user_id'],
                ':driver_name' => $data['driver_name'],
                ':title' => $data['title'],
                ':description' => $data['description']
            ]);
            
            return $this->db->lastInsertId();
        } catch (PDOException $e) {
            error_log("Error creating suggestion: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get all suggestions
     */
    public function getAll($status = null, $limit = 50, $offset = 0) {
        try {
            $sql = "SELECT s.*, u.display_name, u.photo_url
                    FROM {$this->table} s
                    LEFT JOIN users u ON s.user_id = u.user_id";
            
            if ($status) {
                $sql .= " WHERE s.status = :status";
            }
            
            $sql .= " ORDER BY s.created_at DESC LIMIT :limit OFFSET :offset";
            
            $stmt = $this->db->prepare($sql);
            
            if ($status) {
                $stmt->bindValue(':status', $status, PDO::PARAM_STR);
            }
            
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
            $stmt->execute();
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching suggestions: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get suggestion by ID
     */
    public function getById($id) {
        try {
            $sql = "SELECT s.*, u.display_name, u.photo_url
                    FROM {$this->table} s
                    LEFT JOIN users u ON s.user_id = u.user_id
                    WHERE s.id = :id";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':id' => $id]);
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching suggestion: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Update suggestion status and admin response
     */
    public function updateStatus($id, $status, $adminResponse = null) {
        try {
            $sql = "UPDATE {$this->table} 
                    SET status = :status, 
                        admin_response = :admin_response,
                        responded_at = NOW() 
                    WHERE id = :id";
            
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                ':id' => $id,
                ':status' => $status,
                ':admin_response' => $adminResponse
            ]);
        } catch (PDOException $e) {
            error_log("Error updating suggestion: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Delete suggestion
     */
    public function delete($id) {
        try {
            $sql = "DELETE FROM {$this->table} WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':id' => $id]);
        } catch (PDOException $e) {
            error_log("Error deleting suggestion: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get user's suggestions
     */
    public function getUserSuggestions($userId, $limit = 20) {
        try {
            $sql = "SELECT * FROM {$this->table} 
                    WHERE user_id = :user_id 
                    ORDER BY created_at DESC 
                    LIMIT :limit";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':user_id', $userId, PDO::PARAM_STR);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->execute();
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching user suggestions: " . $e->getMessage());
            return [];
        }
    }
}

