-- ============================================================
-- WELTENBIBLIOTHEK v5.11 – Chat & Livestream Fix
-- Datum: 2026-04-02
-- Zweck: Behebt das Problem, dass Nachrichten nicht im Chat
--        erscheinen (RLS-Policy zu restriktiv + fehlende Spalten)
-- AUSFÜHREN in: https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new
-- ============================================================

-- ============================================================
-- 1. SICHERE SPALTEN HINZUFÜGEN (IF NOT EXISTS)
-- ============================================================

-- is_edited: War in v10 noch als is_edited benannt
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS is_edited    BOOLEAN      DEFAULT FALSE;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS deleted_at   TIMESTAMPTZ;

-- edited-Alias (falls noch nicht vorhanden)
-- Hinweis: 'edited' (BOOLEAN) ist bereits in v10 definiert, kein Doppel-Add nötig

-- ============================================================
-- 2. RLS-POLICY FIX: chat_messages INSERT
-- ============================================================
-- Problem: Policy "auth.uid() IS NOT NULL AND auth.uid() = user_id"
--   blockiert den Cloudflare Worker (kein eingeloggter Auth-User)
--   und Nutzer ohne Supabase-Auth (user_id = NULL)
-- Lösung: Anonyme Inserts mit user_id = NULL erlauben

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chat_messages_insert"          ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_anon_insert"     ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_auth_insert"     ON chat_messages;

-- ✅ Neue kombinierte INSERT Policy
CREATE POLICY "chat_messages_insert" ON chat_messages
  FOR INSERT WITH CHECK (
    -- Fall 1: Anonym (kein Auth-User) → user_id MUSS NULL sein
    (auth.uid() IS NULL AND user_id IS NULL)
    -- Fall 2: Eingeloggt mit korrekter UUID → user_id = eigene UUID
    OR (auth.uid() IS NOT NULL AND auth.uid() = user_id)
    -- Fall 3: Eingeloggt, aber user_id nicht gesetzt (Worker mit anon key)
    OR (auth.uid() IS NOT NULL AND user_id IS NULL)
  );

-- SELECT: Nur nicht-gelöschte Nachrichten
DROP POLICY IF EXISTS "chat_messages_select" ON chat_messages;
CREATE POLICY "chat_messages_select" ON chat_messages
  FOR SELECT USING (is_deleted = false);

-- UPDATE (Soft-Delete / Edit): Eigener User oder Admin/Mod
DROP POLICY IF EXISTS "chat_messages_soft_delete" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_update"      ON chat_messages;
CREATE POLICY "chat_messages_update" ON chat_messages
  FOR UPDATE USING (
    auth.uid() = user_id
    OR auth.uid() IN (
      SELECT id FROM profiles
      WHERE role IN ('admin', 'root-admin', 'mod', 'moderator')
    )
  );

-- ============================================================
-- 3. REALTIME AKTIVIEREN FÜR CHAT-TABELLEN
-- ============================================================

-- Stelle sicher, dass Realtime für chat_messages aktiviert ist
-- (wichtig: muss auch im Supabase Dashboard unter Realtime → Tables aktiviert sein!)
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- ============================================================
-- 4. INDEX FÜR PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created
  ON chat_messages(room_id, created_at ASC)
  WHERE is_deleted = false;

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id
  ON chat_messages(room_id);

-- ============================================================
-- 5. FUNKTIONEN: EDIT + SOFT-DELETE via RPC (optional)
-- ============================================================

-- RPC: Nachricht bearbeiten (für authentifizierte Nutzer)
CREATE OR REPLACE FUNCTION edit_chat_message(
  p_message_id  UUID,
  p_new_content TEXT,
  p_user_id     UUID
) RETURNS void AS $$
BEGIN
  UPDATE chat_messages
  SET
    content   = p_new_content,
    message   = p_new_content,
    edited    = TRUE,
    is_edited = TRUE,
    edited_at = NOW()
  WHERE id = p_message_id
    AND user_id = p_user_id
    AND is_deleted = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Nachricht soft-löschen
CREATE OR REPLACE FUNCTION delete_chat_message(
  p_message_id UUID,
  p_user_id    UUID
) RETURNS void AS $$
BEGIN
  UPDATE chat_messages
  SET
    is_deleted = TRUE,
    deleted_at = NOW()
  WHERE id = p_message_id
    AND (
      user_id = p_user_id
      OR p_user_id IN (SELECT id FROM profiles WHERE role IN ('admin','root-admin','mod','moderator'))
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. CHAT ROOMS SEED (falls noch nicht vorhanden)
-- ============================================================

INSERT INTO chat_rooms (id, name, description, world, category, icon, color, is_active) VALUES
  ('meditation',      'Meditation & Achtsamkeit',  'Gemeinsame Meditation',              'energie',  'spiritual', '🧘', '#8B5CF6', true),
  ('astralreisen',    'Astralreisen & Träume',     'Außerkörperliche Erfahrungen',       'energie',  'spiritual', '🌌', '#6366F1', true),
  ('chakren',         'Kundalini & Chakren',       'Chakra-Heilung & Kundalini',         'energie',  'healing',   '🔥', '#EF4444', true),
  ('spiritualitaet',  'Spiritualität & Mystik',    'Mystische Erfahrungen',              'energie',  'spiritual', '🔮', '#A855F7', true),
  ('heilung',         'Energieheilung & Reiki',    'Energiearbeit, Reiki, Fernheilung',  'energie',  'healing',   '💫', '#10B981', true),
  ('politik',         'Geopolitik & Weltordnung',  'Weltpolitik & geheime Agenden',      'materie',  'politics',  '🎭', '#EF4444', true),
  ('geschichte',      'Alternative Geschichte',    'Verborgene Geschichte',              'materie',  'history',   '🏛️', '#F59E0B', true),
  ('ufo',             'UFOs & Außerirdisches',     'Sichtungen & Kontakte',              'materie',  'ufo',       '🛸', '#10B981', true),
  ('verschwoerungen', 'Verschwörungen & Wahrheit', 'Deep State & Geheimgesellschaften',  'materie',  'conspiracy','👁️', '#8B5CF6', true),
  ('wissenschaft',    'Unterdrückte Technologie',  'Freie Energie & Tesla',              'materie',  'science',   '🔬', '#3B82F6', true)
ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      is_active = true;

-- ============================================================
-- FERTIG – Bitte auch im Supabase Dashboard prüfen:
-- 1. Realtime → Tables → chat_messages aktivieren
-- 2. Authentication → Policies → chat_messages INSERT Policy prüfen
-- ============================================================
