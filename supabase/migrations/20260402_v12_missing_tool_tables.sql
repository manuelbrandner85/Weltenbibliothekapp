-- ============================================================
-- WELTENBIBLIOTHEK v5.11 – Fehlende Tool-Tabellen (7 Stück)
-- Datum: 2026-04-02
-- 
-- Diese 7 Tabellen werden von group_tools_service.dart benötigt,
-- existieren aber noch NICHT in der Datenbank.
-- 
-- AUSFÜHREN in:
-- https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new
-- 
-- Endpunkt → Tabelle:
--   energie/astral      → tool_meditation_sessions
--   energie/crystals    → tool_kristalle
--   materie/geopolitics → tool_geopolitics_events
--   materie/history     → tool_history_events
--   materie/healing     → tool_healing_methods
--   materie/network     → tool_network_connections
--   materie/research    → tool_research_documents
-- ============================================================

-- ============================================================
-- 1. tool_meditation_sessions  (energie/astral)
-- Felder aus group_tools_service.dart → createAstralEntry()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_meditation_sessions (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id      TEXT        NOT NULL,
  user_id      UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username     TEXT        DEFAULT 'Anonym',
  title        TEXT        NOT NULL,
  experience   TEXT,
  techniques_used  TEXT[],
  success_level    INTEGER DEFAULT 5 CHECK (success_level BETWEEN 1 AND 10),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_meditation_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_meditation_sessions_select" ON tool_meditation_sessions;
DROP POLICY IF EXISTS "tool_meditation_sessions_insert" ON tool_meditation_sessions;
DROP POLICY IF EXISTS "tool_meditation_sessions_delete" ON tool_meditation_sessions;
CREATE POLICY "tool_meditation_sessions_select" ON tool_meditation_sessions FOR SELECT USING (true);
CREATE POLICY "tool_meditation_sessions_insert" ON tool_meditation_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_meditation_sessions_delete" ON tool_meditation_sessions FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_meditation_sessions_room ON tool_meditation_sessions(room_id, created_at DESC);

-- ============================================================
-- 2. tool_kristalle  (energie/crystals)
-- Felder aus group_tools_service.dart → addCrystal()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_kristalle (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id      TEXT        NOT NULL,
  user_id      UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username     TEXT        DEFAULT 'Anonym',
  crystal_name TEXT        NOT NULL,
  crystal_type TEXT,
  properties   TEXT[],
  uses         TEXT[],
  image_url    TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_kristalle ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_kristalle_select" ON tool_kristalle;
DROP POLICY IF EXISTS "tool_kristalle_insert" ON tool_kristalle;
DROP POLICY IF EXISTS "tool_kristalle_delete" ON tool_kristalle;
CREATE POLICY "tool_kristalle_select" ON tool_kristalle FOR SELECT USING (true);
CREATE POLICY "tool_kristalle_insert" ON tool_kristalle FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_kristalle_delete" ON tool_kristalle FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_kristalle_room ON tool_kristalle(room_id, created_at DESC);

-- ============================================================
-- 3. tool_geopolitics_events  (materie/geopolitics)
-- Felder aus group_tools_service.dart → createGeopoliticsEvent()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_geopolitics_events (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id           TEXT        NOT NULL,
  user_id           UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username          TEXT        DEFAULT 'Anonym',
  event_title       TEXT        NOT NULL,
  event_description TEXT,
  tags              TEXT[],
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_geopolitics_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_geopolitics_events_select" ON tool_geopolitics_events;
DROP POLICY IF EXISTS "tool_geopolitics_events_insert" ON tool_geopolitics_events;
DROP POLICY IF EXISTS "tool_geopolitics_events_delete" ON tool_geopolitics_events;
CREATE POLICY "tool_geopolitics_events_select" ON tool_geopolitics_events FOR SELECT USING (true);
CREATE POLICY "tool_geopolitics_events_insert" ON tool_geopolitics_events FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_geopolitics_events_delete" ON tool_geopolitics_events FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_geopolitics_events_room ON tool_geopolitics_events(room_id, created_at DESC);

-- ============================================================
-- 4. tool_history_events  (materie/history)
-- Felder aus group_tools_service.dart → createHistoryEvent()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_history_events (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id            TEXT        NOT NULL,
  user_id            UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username           TEXT        DEFAULT 'Anonym',
  event_title        TEXT        NOT NULL,
  event_description  TEXT,
  event_year         INTEGER,
  civilization       TEXT,
  category           TEXT,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_history_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_history_events_select" ON tool_history_events;
DROP POLICY IF EXISTS "tool_history_events_insert" ON tool_history_events;
DROP POLICY IF EXISTS "tool_history_events_delete" ON tool_history_events;
CREATE POLICY "tool_history_events_select" ON tool_history_events FOR SELECT USING (true);
CREATE POLICY "tool_history_events_insert" ON tool_history_events FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_history_events_delete" ON tool_history_events FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_history_events_room ON tool_history_events(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tool_history_events_year ON tool_history_events(event_year);

-- ============================================================
-- 5. tool_healing_methods  (materie/healing)
-- Felder aus group_tools_service.dart → addHealingMethod()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_healing_methods (
  id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id             TEXT        NOT NULL,
  user_id             UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username            TEXT        DEFAULT 'Anonym',
  method_name         TEXT        NOT NULL,
  method_description  TEXT,
  category            TEXT        DEFAULT 'alternative',
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_healing_methods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_healing_methods_select" ON tool_healing_methods;
DROP POLICY IF EXISTS "tool_healing_methods_insert" ON tool_healing_methods;
DROP POLICY IF EXISTS "tool_healing_methods_delete" ON tool_healing_methods;
CREATE POLICY "tool_healing_methods_select" ON tool_healing_methods FOR SELECT USING (true);
CREATE POLICY "tool_healing_methods_insert" ON tool_healing_methods FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_healing_methods_delete" ON tool_healing_methods FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_healing_methods_room ON tool_healing_methods(room_id, created_at DESC);

-- ============================================================
-- 6. tool_network_connections  (materie/network)
-- Felder aus group_tools_service.dart → addNetworkConnection()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_network_connections (
  id                      UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id                 TEXT        NOT NULL,
  user_id                 UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username                TEXT        DEFAULT 'Anonym',
  connection_title        TEXT        NOT NULL,
  connection_description  TEXT,
  created_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_network_connections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_network_connections_select" ON tool_network_connections;
DROP POLICY IF EXISTS "tool_network_connections_insert" ON tool_network_connections;
DROP POLICY IF EXISTS "tool_network_connections_delete" ON tool_network_connections;
CREATE POLICY "tool_network_connections_select" ON tool_network_connections FOR SELECT USING (true);
CREATE POLICY "tool_network_connections_insert" ON tool_network_connections FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_network_connections_delete" ON tool_network_connections FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_network_connections_room ON tool_network_connections(room_id, created_at DESC);

-- ============================================================
-- 7. tool_research_documents  (materie/research)
-- Felder aus group_tools_service.dart → addResearchDocument()
-- ============================================================
CREATE TABLE IF NOT EXISTS tool_research_documents (
  id                    UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id               TEXT        NOT NULL,
  user_id               UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  username              TEXT        DEFAULT 'Anonym',
  document_title        TEXT        NOT NULL,
  document_description  TEXT,
  document_type         TEXT        DEFAULT 'research',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tool_research_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tool_research_documents_select" ON tool_research_documents;
DROP POLICY IF EXISTS "tool_research_documents_insert" ON tool_research_documents;
DROP POLICY IF EXISTS "tool_research_documents_delete" ON tool_research_documents;
CREATE POLICY "tool_research_documents_select" ON tool_research_documents FOR SELECT USING (true);
CREATE POLICY "tool_research_documents_insert" ON tool_research_documents FOR INSERT WITH CHECK (true);
CREATE POLICY "tool_research_documents_delete" ON tool_research_documents FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_tool_research_documents_room ON tool_research_documents(room_id, created_at DESC);

-- ============================================================
-- WORKER TOOLMAP UPDATE (in workers/api-worker.js hinzufügen)
-- Diese Endpoints in toolTableMap eintragen:
--   'astral':       'tool_meditation_sessions',
--   'crystals':     'tool_kristalle',
--   'geopolitics':  'tool_geopolitics_events',
--   'history':      'tool_history_events',
--   'healing':      'tool_healing_methods',
--   'network':      'tool_network_connections',
--   'research':     'tool_research_documents',
-- ============================================================
