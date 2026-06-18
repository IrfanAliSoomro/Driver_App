<?php

require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/DateTimeHelper.php';

class PriceAlertModel {
    private $db;
    private $table = 'price_alerts';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create a new price alert
     */
    public function create($data) {
        try {
            // Validate required fields
            if (empty($data['user_id']) || empty($data['pickup']) || empty($data['dropoff']) || empty($data['price'])) {
                error_log("Missing required fields for price alert creation");
                error_log("Data received: " . json_encode($data));
                return false;
            }
            
            $sql = "INSERT INTO {$this->table} 
                    (user_id, pickup, dropoff, price, created_at) 
                    VALUES (:user_id, :pickup, :dropoff, :price, UTC_TIMESTAMP())";
            
            $stmt = $this->db->prepare($sql);
            $result = $stmt->execute([
                ':user_id' => $data['user_id'],
                ':pickup' => $data['pickup'],
                ':dropoff' => $data['dropoff'],
                ':price' => $data['price']
            ]);
            
            if ($result) {
                return $this->db->lastInsertId();
            } else {
                error_log("Failed to execute INSERT statement for price alert");
                return false;
            }
        } catch (PDOException $e) {
            error_log("Error creating price alert: " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            return false;
        }
    }

    /**
     * Get all price alerts
     */
    public function getAll($limit = 50, $offset = 0) {
        try {
            $sql = "SELECT pa.*, u.display_name, u.photo_url,
                           (SELECT COUNT(*) FROM price_alert_likes WHERE alert_id = pa.id AND type = 'like') as likes_count,
                           (SELECT COUNT(*) FROM price_alert_likes WHERE alert_id = pa.id AND type = 'dislike') as dislikes_count
                    FROM {$this->table} pa
                    LEFT JOIN users u ON pa.user_id = u.user_id
                    ORDER BY pa.created_at DESC
                    LIMIT :limit OFFSET :offset";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
            $stmt->execute();
            
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $row) {
                $rows[$i] = $this->formatAlertRow($row);
            }
            return $rows;
        } catch (PDOException $e) {
            error_log("Error fetching price alerts: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get price alert by ID
     */
    public function getById($id) {
        try {
            $sql = "SELECT pa.*, u.display_name, u.photo_url,
                           (SELECT COUNT(*) FROM price_alert_likes WHERE alert_id = pa.id AND type = 'like') as likes_count,
                           (SELECT COUNT(*) FROM price_alert_likes WHERE alert_id = pa.id AND type = 'dislike') as dislikes_count
                    FROM {$this->table} pa
                    LEFT JOIN users u ON pa.user_id = u.user_id
                    WHERE pa.id = :id";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':id' => $id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            return $row ? $this->formatAlertRow($row) : null;
        } catch (PDOException $e) {
            error_log("Error fetching price alert: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Update price alert
     */
    public function update($id, $data) {
        try {
            $sql = "UPDATE {$this->table} 
                    SET pickup = :pickup, 
                        dropoff = :dropoff, 
                        price = :price,
                        updated_at = UTC_TIMESTAMP()
                    WHERE id = :id";
            
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                ':id' => $id,
                ':pickup' => $data['pickup'],
                ':dropoff' => $data['dropoff'],
                ':price' => $data['price']
            ]);
        } catch (PDOException $e) {
            error_log("Error updating price alert: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Delete price alert
     */
    public function delete($id) {
        try {
            // First delete all likes/dislikes
            $sql = "DELETE FROM price_alert_likes WHERE alert_id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':id' => $id]);

            // Then delete the alert
            $sql = "DELETE FROM {$this->table} WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':id' => $id]);
        } catch (PDOException $e) {
            error_log("Error deleting price alert: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Add like/dislike to price alert
     */
    public function addReaction($alertId, $userId, $type) {
        try {
            // Remove any existing reaction from this user
            $sql = "DELETE FROM price_alert_likes WHERE alert_id = :alert_id AND user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':alert_id' => $alertId, ':user_id' => $userId]);

            // Add new reaction
            $sql = "INSERT INTO price_alert_likes (alert_id, user_id, type, created_at) 
                    VALUES (:alert_id, :user_id, :type, UTC_TIMESTAMP())";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                ':alert_id' => $alertId,
                ':user_id' => $userId,
                ':type' => $type
            ]);
        } catch (PDOException $e) {
            error_log("Error adding reaction: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Remove like/dislike from price alert
     */
    public function removeReaction($alertId, $userId) {
        try {
            $sql = "DELETE FROM price_alert_likes WHERE alert_id = :alert_id AND user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':alert_id' => $alertId, ':user_id' => $userId]);
        } catch (PDOException $e) {
            error_log("Error removing reaction: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get user's reaction to an alert
     */
    public function getUserReaction($alertId, $userId) {
        try {
            $sql = "SELECT type FROM price_alert_likes WHERE alert_id = :alert_id AND user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':alert_id' => $alertId, ':user_id' => $userId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result ? $result['type'] : null;
        } catch (PDOException $e) {
            error_log("Error fetching user reaction: " . $e->getMessage());
            return null;
        }
    }

    /**
     * API: expose instants as ISO 8601 UTC so clients can convert to local timezone.
     *
     * @param array<string,mixed> $row
     * @return array<string,mixed>
     */
    private function formatAlertRow(array $row) {
        return DateTimeHelper::rowDatetimeKeysToIso8601Utc($row, ['created_at', 'updated_at']);
    }
}

