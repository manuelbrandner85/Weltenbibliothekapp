-- v95: user_activity_log + fn_add_user_xp RPC
-- Echtzeit-Tagging fuer User-Aktionen (Tool-Open, Chat, Profil-Edit, ...).
-- Idempotent + nullable Felder, daher mehrfach ausfuehrbar.

CREATE TABLE IF NOT EXISTS user_activity_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username TEXT,
  kind TEXT NOT NULL,
  world TEXT NOT NULL DEFAULT 'meta',
  label TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  xp INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_log_user_created
  ON user_activity_log(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_log_kind_created
  ON user_activity_log(kind, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_log_world_created
  ON user_activity_log(world, created_at DESC);

-- RLS aktivieren: User sieht nur eigene Eintraege, Admin sieht alle.
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "activity_select_own" ON user_activity_log;
CREATE POLICY "activity_select_own" ON user_activity_log
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "activity_admin_all" ON user_activity_log;
CREATE POLICY "activity_admin_all" ON user_activity_log
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin', 'root_admin', 'moderator')
    )
  );

-- Service-Role darf direkt schreiben (Worker-Endpoint).
GRANT INSERT, SELECT ON user_activity_log TO service_role;

-- ── XP-Add-RPC ──────────────────────────────────────────────────────────
-- Atomar Punkte zu profiles.xp addieren. Idempotenz NICHT garantiert --
-- die App ist verantwortlich fuer Dedupe-Logik (z.B. tool_open einmal
-- pro Session). Source-Argument dient nur fuer Audit-Spalten falls
-- spaeter erweitert.

CREATE OR REPLACE FUNCTION fn_add_user_xp(
  p_user_id UUID,
  p_amount INT,
  p_source TEXT DEFAULT 'activity'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_xp INT;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RETURN 0;
  END IF;
  -- xp-Spalte ergaenzen falls nicht vorhanden.
  BEGIN
    UPDATE profiles
       SET xp = COALESCE(xp, 0) + p_amount
     WHERE id = p_user_id
     RETURNING xp INTO v_new_xp;
  EXCEPTION WHEN undefined_column THEN
    -- Spalte fehlt -- still ignorieren statt zu kappen.
    RETURN 0;
  END;
  RETURN COALESCE(v_new_xp, 0);
END;
$$;

GRANT EXECUTE ON FUNCTION fn_add_user_xp(UUID, INT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION fn_add_user_xp(UUID, INT, TEXT) TO authenticated;
