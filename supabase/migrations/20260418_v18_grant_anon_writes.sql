-- ============================================================
-- MIGRATION v18 – GRANT INSERT/UPDATE/DELETE für anon/authenticated
-- (idempotent — GRANTs sind re-applied-safe, 3. Versuch via Session-Pooler Port 5432)
-- ============================================================
-- Fix für: PostgrestException "permission denied for table chat_messages"
-- (code 42501).
--
-- Root Cause: v16 erstellte RLS-Policies (FOR INSERT WITH CHECK (true)),
-- die aber von Postgres erst nach einem Table-Level GRANT überhaupt
-- evaluiert werden. v16 setzte nur SELECT als Default-Privilege.
--
-- Dieser Fix ergänzt die fehlenden Write-Grants für die Tabellen,
-- die Flutter direkt via anon/authenticated Key beschreibt.
-- ============================================================

-- Chat: Flutter schreibt direkt (Realtime-UX)
GRANT INSERT, UPDATE, DELETE ON chat_messages     TO anon, authenticated;
GRANT INSERT, DELETE         ON message_reactions TO anon, authenticated;

-- Community-Likes: Flutter toggled direkt
GRANT INSERT, DELETE         ON likes             TO anon, authenticated;

-- Voice: join/leave direkt
GRANT INSERT, UPDATE, DELETE ON voice_participants TO anon, authenticated;

-- Community-Posts: Flutter erstellt/editiert/löscht direkt
-- (Falls v16 Policies fehlten, hier ergänzen)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='community_posts') THEN
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON community_posts TO anon, authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='post_likes') THEN
    EXECUTE 'GRANT INSERT, DELETE ON post_likes TO anon, authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='post_comments') THEN
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON post_comments TO anon, authenticated';
  END IF;
END $$;

-- Research-History: Auth-User speichert eigene Suchen
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='research_history') THEN
    EXECUTE 'GRANT INSERT, DELETE ON research_history TO authenticated';
  END IF;
END $$;

-- Sequences (für SERIAL/IDENTITY-PKs – falls vorhanden)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO anon, authenticated;
-- v6
