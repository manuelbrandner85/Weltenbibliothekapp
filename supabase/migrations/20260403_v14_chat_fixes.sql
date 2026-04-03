-- ============================================================
-- v14: Chat Fixes - avatar_emoji column + RLS policies
-- ============================================================

-- Add avatar_emoji to chat_messages if it doesn't exist
ALTER TABLE chat_messages 
  ADD COLUMN IF NOT EXISTS avatar_emoji TEXT DEFAULT NULL;

-- Ensure RLS is enabled and public SELECT works
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing select policy if any
DROP POLICY IF EXISTS "chat_messages_select" ON chat_messages;
DROP POLICY IF EXISTS "Anyone can read chat messages" ON chat_messages;
DROP POLICY IF EXISTS "Public read chat_messages" ON chat_messages;

-- Allow anyone to read non-deleted messages
CREATE POLICY "Public read chat_messages" ON chat_messages
  FOR SELECT USING (is_deleted = false OR is_deleted IS NULL);

-- Allow anyone to insert messages (username-based auth)
DROP POLICY IF EXISTS "chat_messages_insert" ON chat_messages;
DROP POLICY IF EXISTS "Anyone can insert chat messages" ON chat_messages;
CREATE POLICY "Anyone can insert chat messages" ON chat_messages
  FOR INSERT WITH CHECK (true);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created 
  ON chat_messages(room_id, created_at ASC)
  WHERE is_deleted = false OR is_deleted IS NULL;

-- Ensure profiles table has public SELECT
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read profiles" ON profiles;
CREATE POLICY "Public read profiles" ON profiles
  FOR SELECT USING (true);

-- ============================================================
-- Fix: Ensure chat_rooms contains expected room IDs
-- ============================================================
INSERT INTO chat_rooms (id, name, description, world, category, icon, color, is_active)
VALUES 
  ('materie-politik', 'Politik', 'Weltpolitik & Geopolitik', 'materie', 'politik', '🏛️', '#FF5252', true),
  ('materie-geschichte', 'Geschichte', 'Verborgene Geschichte', 'materie', 'geschichte', '📜', '#FF9800', true),
  ('materie-ufo', 'UFO & Aliens', 'Außerirdisches & UAP', 'materie', 'ufo', '🛸', '#2196F3', true),
  ('materie-verschwoerung', 'Verschwörungen', 'Theorien & Fakten', 'materie', 'verschwoerung', '🕵️', '#9C27B0', true),
  ('materie-wissenschaft', 'Wissenschaft', 'Alternative Wissenschaft', 'materie', 'wissenschaft', '🔬', '#4CAF50', true),
  ('materie-gesundheit', 'Gesundheit', 'Alternative Heilkunde', 'materie', 'gesundheit', '💚', '#00BCD4', true),
  ('energie-meditation', 'Meditation', 'Meditationserfahrungen', 'energie', 'meditation', '🧘', '#7B1FA2', true),
  ('energie-chakra', 'Chakras', 'Chakra-System', 'energie', 'chakra', '🌈', '#FF9800', true),
  ('energie-astrologie', 'Astrologie', 'Planetare Einflüsse', 'energie', 'astrologie', '⭐', '#4CAF50', true),
  ('energie-heilung', 'Heilung', 'Energetische Heilung', 'energie', 'heilung', '💫', '#E91E63', true),
  ('energie-kristalle', 'Kristalle', 'Kristallenergie', 'energie', 'kristalle', '💎', '#00BCD4', true),
  ('energie-bewusstsein', 'Bewusstsein', 'Bewusstseinsforschung', 'energie', 'bewusstsein', '🧠', '#9C27B0', true),
  ('energie-traeume', 'Traumdeutung', 'Träume & Symbolik', 'energie', 'traeume', '🌙', '#3F51B5', true),
  ('energie-kraftorte', 'Kraftorte', 'Heilige Orte & Ley-Linien', 'energie', 'kraftorte', '🗺️', '#FFD700', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_active = true;
