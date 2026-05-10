-- v55: Performance-Indexes für chat_messages
-- Verbessert Abfragen nach room_id + created_at (Paginierung) und
-- die is_deleted-Filterung. Idempotent via IF NOT EXISTS.

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created
    ON chat_messages (room_id, created_at ASC)
    WHERE is_deleted IS NOT TRUE;

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id
    ON chat_messages (room_id)
    WHERE is_deleted IS NOT TRUE;

-- Partial-Index für message_reactions Lookup
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id
    ON message_reactions (message_id);
