<?php

require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/DateTimeHelper.php';
require_once __DIR__ . '/../includes/ChatGroupHelper.php';

class ChatModel {
    private $db;
    private $table = 'chat_messages';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create a new chat message
     *
     * @param array{group:string,user_id:string,text:string,reply_to_message_id?:int|null} $data
     */
    public function create($data) {
        try {
            $sql = "INSERT INTO {$this->table} 
                    (group_name, user_id, text, reply_to_message_id, created_at) 
                    VALUES (:group_name, :user_id, :text, :reply_to_message_id, UTC_TIMESTAMP())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':group_name' => $data['group'],
                ':user_id' => $data['user_id'],
                ':text' => $data['text'],
                ':reply_to_message_id' => !empty($data['reply_to_message_id'])
                    ? (int)$data['reply_to_message_id']
                    : null,
            ]);
            
            return $this->db->lastInsertId();
        } catch (PDOException $e) {
            error_log("Error creating chat message: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get messages by group
     */
    public function getByGroup($group, $limit = 50, $offset = 0) {
        try {
            $sql = "SELECT cm.*, u.display_name, u.photo_url
                    FROM {$this->table} cm
                    LEFT JOIN users u ON cm.user_id = u.user_id
                    WHERE cm.group_name = :group
                    ORDER BY cm.created_at DESC
                    LIMIT :limit OFFSET :offset";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':group', $group, PDO::PARAM_STR);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
            $stmt->execute();
            
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $row) {
                $rows[$i] = $this->formatMessageRow($row);
            }
            $this->attachReplyPreviews($rows);
            return array_reverse($rows);
        } catch (PDOException $e) {
            error_log("Error fetching chat messages: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get messages after a specific timestamp
     */
    public function getAfterTimestamp($group, $timestamp) {
        try {
            $afterUtc = DateTimeHelper::clientAfterToMysqlUtc($timestamp);
            $sql = "SELECT cm.*, u.display_name, u.photo_url
                    FROM {$this->table} cm
                    LEFT JOIN users u ON cm.user_id = u.user_id
                    WHERE cm.group_name = :group AND cm.created_at > :timestamp
                    ORDER BY cm.created_at ASC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':group' => $group,
                ':timestamp' => $afterUtc
            ]);
            
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $row) {
                $rows[$i] = $this->formatMessageRow($row);
            }
            $this->attachReplyPreviews($rows);
            return $rows;
        } catch (PDOException $e) {
            error_log("Error fetching new messages: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Delete a message
     */
    public function delete($id, $userId) {
        try {
            $sql = "DELETE FROM {$this->table} WHERE id = :id AND user_id = :user_id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':id' => $id, ':user_id' => $userId]);
        } catch (PDOException $e) {
            error_log("Error deleting message: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Delete a message without owner restriction (admin use).
     */
    public function deleteAny($id) {
        try {
            $sql = "DELETE FROM {$this->table} WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([':id' => $id]);
        } catch (PDOException $e) {
            error_log("Error deleting message as admin: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Delete multiple messages owned by the same user. IDs not found or not owned are skipped.
     *
     * @param array<int|string> $ids
     * @return int|false Number of rows deleted, or false on failure
     */
    public function deleteBatchForUser(array $ids, $userId) {
        $ids = array_values(array_unique(array_map('intval', $ids)));
        $ids = array_filter($ids, function ($id) {
            return $id > 0;
        });
        if (empty($ids)) {
            return 0;
        }

        $maxBatch = 100;
        if (count($ids) > $maxBatch) {
            $ids = array_slice($ids, 0, $maxBatch);
        }

        try {
            $placeholders = implode(',', array_fill(0, count($ids), '?'));
            $sql = "DELETE FROM {$this->table} WHERE user_id = ? AND id IN ($placeholders)";
            $params = array_merge([$userId], $ids);
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            return $stmt->rowCount();
        } catch (PDOException $e) {
            error_log("Error batch deleting messages: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Delete multiple messages without owner restriction (admin use).
     *
     * @param array<int|string> $ids
     * @return int|false Number of rows deleted, or false on failure
     */
    public function deleteBatch(array $ids) {
        $ids = array_values(array_unique(array_map('intval', $ids)));
        $ids = array_filter($ids, function ($id) {
            return $id > 0;
        });
        if (empty($ids)) {
            return 0;
        }

        $maxBatch = 100;
        if (count($ids) > $maxBatch) {
            $ids = array_slice($ids, 0, $maxBatch);
        }

        try {
            $placeholders = implode(',', array_fill(0, count($ids), '?'));
            $sql = "DELETE FROM {$this->table} WHERE id IN ($placeholders)";
            $stmt = $this->db->prepare($sql);
            $stmt->execute($ids);
            return $stmt->rowCount();
        } catch (PDOException $e) {
            error_log("Error admin batch deleting messages: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get message count by group
     */
    public function getMessageCount($group) {
        try {
            $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE group_name = :group";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':group' => $group]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['count'];
        } catch (PDOException $e) {
            error_log("Error getting message count: " . $e->getMessage());
            return 0;
        }
    }

    /**
     * Check if a chat group exists
     */
    public function groupExists($group) {
        try {
            return ChatGroupHelper::isValidGroupSlug($group);
        } catch (Exception $e) {
            error_log("Error checking if group exists: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get message by ID
     */
    public function getById($id) {
        try {
            $sql = "SELECT cm.*, u.display_name, u.photo_url
                    FROM {$this->table} cm
                    LEFT JOIN users u ON cm.user_id = u.user_id
                    WHERE cm.id = :id";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':id' => $id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) {
                return false;
            }
            $message = $this->formatMessageRow($row);
            $messages = [$message];
            $this->attachReplyPreviews($messages);
            return $messages[0];
        } catch (PDOException $e) {
            error_log("Error fetching message by ID: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Check if a message exists
     */
    public function messageExists($messageId) {
        try {
            $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([':id' => $messageId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['count'] > 0;
        } catch (PDOException $e) {
            error_log("Error checking if message exists: " . $e->getMessage());
            return false;
        }
    }

    /**
     * @param array<string,mixed> $row
     * @return array<string,mixed>
     */
    private function formatMessageRow(array $row) {
        $row = DateTimeHelper::rowDatetimeKeysToIso8601Utc($row, ['created_at']);
        if (isset($row['text']) && is_string($row['text'])) {
            $row['text'] = html_entity_decode($row['text'], ENT_QUOTES | ENT_HTML5, 'UTF-8');
        }
        if (array_key_exists('reply_to_message_id', $row)) {
            $row['reply_to_message_id'] = $row['reply_to_message_id'] !== null
                ? (int)$row['reply_to_message_id']
                : null;
        } else {
            $row['reply_to_message_id'] = null;
        }
        $row['reply_to'] = null;
        return $row;
    }

    /**
     * @param array<int,array<string,mixed>> $messages
     */
    private function attachReplyPreviews(array &$messages) {
        $parentIds = [];
        foreach ($messages as $msg) {
            if (!empty($msg['reply_to_message_id'])) {
                $parentIds[] = (int)$msg['reply_to_message_id'];
            }
        }
        $parentIds = array_values(array_unique($parentIds));
        if (empty($parentIds)) {
            return;
        }

        $placeholders = implode(',', array_fill(0, count($parentIds), '?'));
        $sql = "SELECT cm.id, cm.group_name, cm.user_id, cm.text, cm.created_at,
                       u.display_name, u.photo_url
                FROM {$this->table} cm
                LEFT JOIN users u ON cm.user_id = u.user_id
                WHERE cm.id IN ($placeholders)";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($parentIds);

        $parents = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $formatted = $this->formatMessageRow($row);
            $parents[(int)$formatted['id']] = $this->buildReplyPreview($formatted);
        }

        foreach ($messages as &$msg) {
            $parentId = $msg['reply_to_message_id'] ?? null;
            if ($parentId && isset($parents[$parentId])) {
                $msg['reply_to'] = $parents[$parentId];
            }
        }
        unset($msg);
    }

    /**
     * @param array<string,mixed> $row
     * @return array<string,mixed>
     */
    private function buildReplyPreview(array $row) {
        return [
            'id' => (int)$row['id'],
            'group_name' => $row['group_name'] ?? null,
            'user_id' => $row['user_id'] ?? null,
            'display_name' => $row['display_name'] ?? null,
            'photo_url' => $row['photo_url'] ?? null,
            'text' => $row['text'] ?? '',
            'created_at' => $row['created_at'] ?? null,
        ];
    }
}

