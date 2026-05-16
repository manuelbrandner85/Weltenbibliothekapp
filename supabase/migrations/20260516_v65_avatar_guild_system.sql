-- ══════════════════════════════════════════════════════════════════════════════
-- v65 — AVATAR + GUILD SYSTEM (AUFGABE 8A + 8B)
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. USER_AVATAR ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_avatar (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  evolution_stage   INTEGER DEFAULT 1 CHECK (evolution_stage BETWEEN 1 AND 5),
  materie_balance   REAL DEFAULT 0,
  energie_balance   REAL DEFAULT 0,
  vorhang_balance   REAL DEFAULT 0,
  ursprung_balance  REAL DEFAULT 0,
  equipped_artifacts TEXT[] DEFAULT '{}',
  custom_title      TEXT,
  updated_at        TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_avatar_user ON public.user_avatar (user_id);

CREATE OR REPLACE FUNCTION public.trg_user_avatar_updated()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_user_avatar_updated ON public.user_avatar;
CREATE TRIGGER trg_user_avatar_updated
  BEFORE UPDATE ON public.user_avatar
  FOR EACH ROW EXECUTE FUNCTION public.trg_user_avatar_updated();

ALTER TABLE public.user_avatar ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "avatar_select_own" ON public.user_avatar;
DROP POLICY IF EXISTS "avatar_insert_own" ON public.user_avatar;
DROP POLICY IF EXISTS "avatar_update_own" ON public.user_avatar;
DROP POLICY IF EXISTS "avatar_select_all" ON public.user_avatar;
CREATE POLICY "avatar_select_all"   ON public.user_avatar FOR SELECT USING (true);
CREATE POLICY "avatar_insert_own"   ON public.user_avatar FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "avatar_update_own"   ON public.user_avatar FOR UPDATE USING (auth.uid() = user_id);

GRANT SELECT ON public.user_avatar TO anon, authenticated;
GRANT INSERT, UPDATE ON public.user_avatar TO authenticated;

-- ── 2. GUILDS ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guilds (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT UNIQUE NOT NULL,
  description   TEXT NOT NULL,
  world         TEXT NOT NULL,
  leader_id     UUID NOT NULL REFERENCES auth.users(id),
  max_members   INTEGER DEFAULT 12,
  member_count  INTEGER DEFAULT 1,
  emblem_icon   TEXT DEFAULT 'shield',
  emblem_color  TEXT DEFAULT '#FFFFFF',
  is_public     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guilds_world  ON public.guilds (world);
CREATE INDEX IF NOT EXISTS idx_guilds_leader ON public.guilds (leader_id);

ALTER TABLE public.guilds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "guilds_select_public" ON public.guilds;
DROP POLICY IF EXISTS "guilds_insert_auth"   ON public.guilds;
DROP POLICY IF EXISTS "guilds_update_leader" ON public.guilds;
DROP POLICY IF EXISTS "guilds_delete_leader" ON public.guilds;
CREATE POLICY "guilds_select_public" ON public.guilds FOR SELECT USING (true);
CREATE POLICY "guilds_insert_auth"   ON public.guilds FOR INSERT WITH CHECK (auth.uid() = leader_id);
CREATE POLICY "guilds_update_leader" ON public.guilds FOR UPDATE USING (auth.uid() = leader_id);
CREATE POLICY "guilds_delete_leader" ON public.guilds FOR DELETE USING (auth.uid() = leader_id);

GRANT SELECT ON public.guilds TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.guilds TO authenticated;

-- ── 3. GUILD_MEMBERS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guild_members (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guild_id  UUID NOT NULL REFERENCES public.guilds(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role      TEXT DEFAULT 'member' CHECK (role IN ('leader', 'elder', 'member')),
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(guild_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_guild_members_guild ON public.guild_members (guild_id);
CREATE INDEX IF NOT EXISTS idx_guild_members_user  ON public.guild_members (user_id);

ALTER TABLE public.guild_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gm_select_all"  ON public.guild_members;
DROP POLICY IF EXISTS "gm_insert_auth" ON public.guild_members;
DROP POLICY IF EXISTS "gm_delete_own"  ON public.guild_members;
CREATE POLICY "gm_select_all"  ON public.guild_members FOR SELECT USING (true);
CREATE POLICY "gm_insert_auth" ON public.guild_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "gm_delete_own"  ON public.guild_members FOR DELETE USING (auth.uid() = user_id);

GRANT SELECT ON public.guild_members TO anon, authenticated;
GRANT INSERT, DELETE ON public.guild_members TO authenticated;

-- ── 4. GUILD_CHALLENGES ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guild_challenges (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guild_id       UUID NOT NULL REFERENCES public.guilds(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT NOT NULL,
  challenge_type TEXT NOT NULL CHECK (challenge_type IN
    ('silence','manifestation','quiz','shadow','frequency','remote_viewing')),
  duration_days  INTEGER DEFAULT 7,
  start_date     DATE NOT NULL,
  end_date       DATE NOT NULL,
  goal_value     INTEGER,
  reward_xp      INTEGER DEFAULT 200,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guild_challenges_guild ON public.guild_challenges (guild_id);

ALTER TABLE public.guild_challenges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gc_select_all"    ON public.guild_challenges;
DROP POLICY IF EXISTS "gc_insert_member" ON public.guild_challenges;
CREATE POLICY "gc_select_all" ON public.guild_challenges FOR SELECT USING (true);
CREATE POLICY "gc_insert_member" ON public.guild_challenges FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.guild_members
    WHERE guild_id = guild_challenges.guild_id
      AND user_id = auth.uid()
      AND role IN ('leader','elder')
  )
);

GRANT SELECT ON public.guild_challenges TO anon, authenticated;
GRANT INSERT ON public.guild_challenges TO authenticated;

-- ── 5. GUILD_CHALLENGE_PROGRESS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guild_challenge_progress (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id  UUID NOT NULL REFERENCES public.guild_challenges(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_value INTEGER DEFAULT 0,
  completed     BOOLEAN DEFAULT false,
  completed_at  TIMESTAMPTZ,
  UNIQUE(challenge_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_gcp_challenge ON public.guild_challenge_progress (challenge_id);
CREATE INDEX IF NOT EXISTS idx_gcp_user      ON public.guild_challenge_progress (user_id);

ALTER TABLE public.guild_challenge_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gcp_select_all"  ON public.guild_challenge_progress;
DROP POLICY IF EXISTS "gcp_insert_own"  ON public.guild_challenge_progress;
DROP POLICY IF EXISTS "gcp_update_own"  ON public.guild_challenge_progress;
CREATE POLICY "gcp_select_all"  ON public.guild_challenge_progress FOR SELECT USING (true);
CREATE POLICY "gcp_insert_own"  ON public.guild_challenge_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "gcp_update_own"  ON public.guild_challenge_progress FOR UPDATE USING (auth.uid() = user_id);

GRANT SELECT ON public.guild_challenge_progress TO anon, authenticated;
GRANT INSERT, UPDATE ON public.guild_challenge_progress TO authenticated;

-- ── 6. REALTIME (idempotent via pg_publication_tables) ──────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='guilds') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.guilds;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='guild_members') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.guild_members;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='guild_challenge_progress') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.guild_challenge_progress;
  END IF;
END$$;
