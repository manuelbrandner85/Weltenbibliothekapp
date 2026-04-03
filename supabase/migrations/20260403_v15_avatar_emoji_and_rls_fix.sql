-- ============================================================
-- v15: avatar_emoji Spalten + erweiterte Roles-Constraint
-- Angewendet: 2026-04-03 via direktem DB-Zugang (eu-west-1 pooler)
-- ============================================================

-- 1. avatar_emoji zu chat_messages hinzufügen
ALTER TABLE chat_messages 
  ADD COLUMN IF NOT EXISTS avatar_emoji TEXT DEFAULT NULL;

-- 2. avatar_emoji zu profiles hinzufügen  
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS avatar_emoji TEXT DEFAULT NULL;

-- 3. Role Constraint erweitern: root_admin und content_editor erlauben
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role = ANY (ARRAY['user', 'moderator', 'admin', 'root_admin', 'content_editor']));

-- 4. Performance-Indizes für Chat
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created 
  ON chat_messages(room_id, created_at ASC) 
  WHERE is_deleted = false OR is_deleted IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_messages_username
  ON chat_messages(username);

-- 5. RLS: öffentliches INSERT und SELECT für anonyme Nutzer
--    (Service Role Key bypassed RLS automatisch)
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can insert chat messages" ON chat_messages;
CREATE POLICY "Anyone can insert chat messages" ON chat_messages
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public read chat_messages" ON chat_messages;
CREATE POLICY "Public read chat_messages" ON chat_messages
  FOR SELECT USING (is_deleted = false OR is_deleted IS NULL);
