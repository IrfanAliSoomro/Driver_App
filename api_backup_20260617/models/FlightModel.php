<?php

require_once __DIR__ . '/../includes/Database.php';

class FlightModel {
    private $db;
    private $table = 'flight_data';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create or update flight data
     */
    public function createOrUpdate($data) {
        try {
            $sql = "INSERT INTO {$this->table} 
                    (flight_id, airline, flight_number, destination, scheduled_time, 
                     status, gate, airline_code, is_arrival, last_updated) 
                    VALUES (:flight_id, :airline, :flight_number, :destination, :scheduled_time,
                            :status, :gate, :airline_code, :is_arrival, NOW())
                    ON DUPLICATE KEY UPDATE 
                    airline = :airline,
                    destination = :destination,
                    scheduled_time = :scheduled_time,
                    status = :status,
                    gate = :gate,
                    last_updated = NOW()";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':flight_id' => $data['id'],
                ':airline' => $data['airline'],
                ':flight_number' => $data['flight_number'],
                ':destination' => $data['destination'],
                ':scheduled_time' => $data['scheduled_time'],
                ':status' => $data['status'],
                ':gate' => $data['gate'],
                ':airline_code' => $data['airline_code'],
                ':is_arrival' => $data['is_arrival'] ? 1 : 0
            ]);
            
            return true;
        } catch (PDOException $e) {
            error_log("Error creating/updating flight: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get all flights
     */
    public function getAll($isArrival = null, $limit = 100) {
        try {
            $sql = "SELECT * FROM {$this->table}";
            
            if ($isArrival !== null) {
                $sql .= " WHERE is_arrival = :is_arrival";
            }
            
            $sql .= " ORDER BY scheduled_time ASC LIMIT :limit";
            
            $stmt = $this->db->prepare($sql);
            
            if ($isArrival !== null) {
                $stmt->bindValue(':is_arrival', $isArrival ? 1 : 0, PDO::PARAM_INT);
            }
            
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->execute();
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching flights: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get flight by ID
     */
    public function getById($flightId) {
        try {
            $sql = "SELECT * FROM {$this->table} WHERE flight_id = :flight_id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':flight_id' => $flightId]);
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching flight: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Search flights
     */
    public function search($query, $limit = 50) {
        try {
            $searchTerm = "%{$query}%";
            $sql = "SELECT * FROM {$this->table} 
                    WHERE flight_number LIKE :query 
                    OR airline LIKE :query 
                    OR destination LIKE :query
                    ORDER BY scheduled_time ASC 
                    LIMIT :limit";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':query', $searchTerm, PDO::PARAM_STR);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->execute();
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error searching flights: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Delete old flights
     */
    public function deleteOld($hours = 24) {
        try {
            $sql = "DELETE FROM {$this->table} 
                    WHERE last_updated < DATE_SUB(NOW(), INTERVAL :hours HOUR)";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':hours' => $hours]);
            return $stmt->rowCount();
        } catch (PDOException $e) {
            error_log("Error deleting old flights: " . $e->getMessage());
            return 0;
        }
    }
}

