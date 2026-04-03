-- ============================================================
-- MIGRATION v13: Read Receipts, Push Subscriptions, Typing
-- ============================================================

-- ── 1. READ RECEIPTS: read_by Spalte zu chat_messages hinzufügen ──

ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS read_by TEXT[] NOT NULL DEFAULT '{}';

-- Index für schnelle Array-Suche
CREATE INDEX IF NOT EXISTS idx_chat_messages_read_by
  ON chat_messages USING GIN (read_by);

-- ── 2. RPC: mark_message_as_read ──────────────────────────────────
-- Fügt userId atomic zum read_by-Array hinzu (keine Duplikate).

CREATE OR REPLACE FUNCTION mark_message_as_read(
  p_message_id TEXT,
  p_user_id    TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE chat_messages
  SET read_by = array_append(read_by, p_user_id)
  WHERE id = p_message_id
    AND NOT (p_user_id = ANY(read_by));
END;
$$;

-- ── 3. RPC: mark_room_messages_as_read ────────────────────────────
-- Markiert alle ungelesenen Nachrichten eines Raums als gelesen.

CREATE OR REPLACE FUNCTION mark_room_messages_as_read(
  p_room_id TEXT,
  p_user_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE chat_messages
  SET read_by = array_append(read_by, p_user_id)
  WHERE room_id = p_room_id
    AND is_deleted = FALSE
    AND NOT (p_user_id = ANY(read_by));
END;
$$;

-- ── 4. PUSH NOTIFICATION SUBSCRIPTIONS TABLE ──────────────────────

CREATE TABLE IF NOT EXISTS push_subscriptions (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  endpoint     TEXT    NOT NULL,
  p256dh       TEXT    NOT NULL,
  auth_key     TEXT    NOT NULL,
  platform     TEXT    NOT NULL DEFAULT 'web',  -- 'web' | 'fcm' | 'apns'
  fcm_token    TEXT,
  device_info  JSONB   DEFAULT '{}',
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, endpoint)
);

-- RLS für push_subscriptions
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own push subscriptions"
  ON push_subscriptions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id
  ON push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_active
  ON push_subscriptions(is_active) WHERE is_active = TRUE;

-- ── 5. NOTIFICATION QUEUE TABLE (für Edge Function) ───────────────

CREATE TABLE IF NOT EXISTS notification_queue (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title        TEXT    NOT NULL,
  body         TEXT    NOT NULL,
  data         JSONB   DEFAULT '{}',
  status       TEXT    NOT NULL DEFAULT 'pending',  -- 'pending' | 'sent' | 'failed'
  attempts     INT     NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Index für die Edge Function
CREATE INDEX IF NOT EXISTS idx_notification_queue_pending
  ON notification_queue(status, created_at)
  WHERE status = 'pending';

-- ── 6. TRIGGER: Neue Chat-Nachricht → Notification Queue ──────────

CREATE OR REPLACE FUNCTION trigger_chat_message_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_room_name  TEXT;
  v_recipients UUID[];
  v_uid        UUID;
BEGIN
  -- Raum-Namen laden
  SELECT name INTO v_room_name
  FROM chat_rooms
  WHERE id = NEW.room_id;

  -- Alle User in dem Raum finden (aus room_members oder chat_rooms.participants)
  -- Fallback: alle aktiven User mit push_subscriptions
  SELECT ARRAY(
    SELECT DISTINCT ps.user_id
    FROM push_subscriptions ps
    WHERE ps.is_active = TRUE
      AND ps.user_id != NEW.user_id::UUID
  ) INTO v_recipients;

  -- Notification für jeden Empfänger einreihen
  FOREACH v_uid IN ARRAY v_recipients
  LOOP
    INSERT INTO notification_queue (user_id, title, body, data)
    VALUES (
      v_uid,
      COALESCE(v_room_name, 'Chat') || ' – Neue Nachricht',
      NEW.username || ': ' || LEFT(COALESCE(NEW.content, NEW.message, ''), 100),
      jsonb_build_object(
        'type', 'chat_message',
        'roomId', NEW.room_id,
        'messageId', NEW.id,
        'senderId', NEW.user_id,
        'senderName', NEW.username
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- Trigger nur wenn nicht already exists
DROP TRIGGER IF EXISTS chat_message_push_trigger ON chat_messages;
CREATE TRIGGER chat_message_push_trigger
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  WHEN (NEW.is_deleted = FALSE)
  EXECUTE FUNCTION trigger_chat_message_notification();

-- ── 7. Realtime für chat_messages UPDATE aktivieren ───────────────
-- (für read_by-Änderungen via Realtime zu empfangen)

ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
