-- v103: Admin-Dashboard Persistierung + Reports
-- Phase 3a + 3e + 4h aus dem grossen Refactor.
-- Erstellt:
--   admin_actions     -- Audit-Trail aller Admin-Aktionen
--   admin_bans        -- Persistente Bans (vorher In-Memory!)
--   admin_warnings    -- 3-Strike-Warning-System
--   reported_messages -- User-Reports auf Chat-Nachrichten
--   reported_posts    -- User-Reports auf Community-Posts
--
-- Alle Tabellen haben RLS aktiv:
--   - Admins/Mods (role IN admin/root_admin/moderator) duerfen lesen+schreiben.
--   - Eingeloggte User duerfen Reports erstellen (nur eigene).

-- ── 1. admin_actions ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_actions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        TEXT NOT NULL,
  admin_username  TEXT NOT NULL,
  target_user_id  TEXT NOT NULL,
  target_username TEXT NOT NULL,
  action_type     TEXT NOT NULL CHECK (action_type IN (
                    'kick','mute','unmute','ban','unban','timeout',
                    'warning','delete_message','slow_mode','promote',
                    'demote','role_change')),
  reason          TEXT,
  room_id         TEXT,
  duration        TEXT,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_actions_target
  ON public.admin_actions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_created
  ON public.admin_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_actions_type
  ON public.admin_actions(action_type);

ALTER TABLE public.admin_actions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_actions_read" ON public.admin_actions;
CREATE POLICY "admin_actions_read" ON public.admin_actions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "admin_actions_write" ON public.admin_actions;
CREATE POLICY "admin_actions_write" ON public.admin_actions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
  );

-- ── 2. admin_bans ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_bans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL UNIQUE,
  username        TEXT NOT NULL,
  admin_id        TEXT NOT NULL,
  admin_username  TEXT NOT NULL,
  reason          TEXT,
  is_permanent    BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_bans_user
  ON public.admin_bans(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_bans_active
  ON public.admin_bans(user_id) WHERE is_permanent = TRUE OR expires_at > NOW();

ALTER TABLE public.admin_bans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_bans_read" ON public.admin_bans;
CREATE POLICY "admin_bans_read" ON public.admin_bans
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
    OR auth.uid()::text = user_id
  );

DROP POLICY IF EXISTS "admin_bans_write" ON public.admin_bans;
CREATE POLICY "admin_bans_write" ON public.admin_bans
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
  );

-- ── 3. admin_warnings ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_warnings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL,
  username        TEXT NOT NULL,
  admin_id        TEXT NOT NULL,
  admin_username  TEXT NOT NULL,
  reason          TEXT NOT NULL,
  room_id         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_warnings_user
  ON public.admin_warnings(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_warnings_created
  ON public.admin_warnings(created_at DESC);

ALTER TABLE public.admin_warnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_warnings_read" ON public.admin_warnings;
CREATE POLICY "admin_warnings_read" ON public.admin_warnings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
    OR auth.uid()::text = user_id
  );

DROP POLICY IF EXISTS "admin_warnings_write" ON public.admin_warnings;
CREATE POLICY "admin_warnings_write" ON public.admin_warnings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
  );

-- ── 4. reported_messages ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reported_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id      TEXT NOT NULL,
  room_id         TEXT,
  reporter_id     TEXT NOT NULL,
  reporter_name   TEXT,
  target_user     TEXT,
  reason          TEXT NOT NULL DEFAULT 'other',
  notes           TEXT,
  status          TEXT NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open','reviewed','dismissed','actioned')),
  reviewed_by     TEXT,
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reported_messages_status
  ON public.reported_messages(status);
CREATE INDEX IF NOT EXISTS idx_reported_messages_created
  ON public.reported_messages(created_at DESC);

ALTER TABLE public.reported_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reports_user_insert" ON public.reported_messages;
CREATE POLICY "reports_user_insert" ON public.reported_messages
  FOR INSERT WITH CHECK (
    auth.uid()::text = reporter_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "reports_admin_all" ON public.reported_messages;
CREATE POLICY "reports_admin_all" ON public.reported_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
  );

-- ── 5. reported_posts ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reported_posts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id           TEXT NOT NULL,
  reporter_id       TEXT NOT NULL,
  reporter_name     TEXT,
  author_username   TEXT,
  reason            TEXT NOT NULL DEFAULT 'other',
  notes             TEXT,
  status            TEXT NOT NULL DEFAULT 'open'
                      CHECK (status IN ('open','reviewed','dismissed','actioned')),
  reviewed_by       TEXT,
  reviewed_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reported_posts_status
  ON public.reported_posts(status);
CREATE INDEX IF NOT EXISTS idx_reported_posts_created
  ON public.reported_posts(created_at DESC);

ALTER TABLE public.reported_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reported_posts_user_insert" ON public.reported_posts;
CREATE POLICY "reported_posts_user_insert" ON public.reported_posts
  FOR INSERT WITH CHECK (
    auth.uid()::text = reporter_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "reported_posts_admin_all" ON public.reported_posts;
CREATE POLICY "reported_posts_admin_all" ON public.reported_posts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.role() = 'service_role'
  );
