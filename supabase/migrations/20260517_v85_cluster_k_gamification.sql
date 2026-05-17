-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v85 – Cluster K: Gamification-Erweiterungen
--
-- K1 user_achievements_tiers — Bronze/Silver/Gold/Platinum-Stufen
-- K2 daily_challenges_active — täglich aktive Welt-Challenges
-- K3 leaderboard_weekly      — Wochen-Snapshots + Hall of Fame
-- K5 guild_quests + _progress— wöchentliche Gruppen-Quests
-- K6 destiny_weekly_draws    — automatische Sonntag-Ziehung
-- ═══════════════════════════════════════════════════════════════

-- K1 ──────────────────────────────────────────────────────────
-- Erweitert user_achievements um eine `tier`-Spalte (idempotent).
ALTER TABLE IF EXISTS public.user_achievements
  ADD COLUMN IF NOT EXISTS tier text NOT NULL DEFAULT 'bronze' CHECK (tier IN ('bronze','silver','gold','platinum'));

-- K2 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_challenges_active (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  active_date  date NOT NULL,
  world        text NOT NULL,             -- materie/energie/vorhang/ursprung
  code         text NOT NULL,             -- z.B. 'finish_module', 'meditate_5min'
  title        text NOT NULL,
  description  text,
  target_count smallint NOT NULL DEFAULT 1,
  xp_reward    smallint NOT NULL DEFAULT 50,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (active_date, world, code)
);

CREATE INDEX IF NOT EXISTS idx_daily_chal_date_world
  ON public.daily_challenges_active (active_date DESC, world);

ALTER TABLE public.daily_challenges_active ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS dc_read ON public.daily_challenges_active;
CREATE POLICY dc_read ON public.daily_challenges_active FOR SELECT USING (true);

-- K3 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.leaderboard_weekly (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start      date NOT NULL,
  user_id         text NOT NULL,
  username        text,
  world           text NOT NULL,
  weekly_xp       int NOT NULL,
  weekly_rank     smallint NOT NULL,
  is_hall_of_fame boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (week_start, world, user_id)
);

CREATE INDEX IF NOT EXISTS idx_lb_weekly_week_world_xp
  ON public.leaderboard_weekly (week_start DESC, world, weekly_xp DESC);
CREATE INDEX IF NOT EXISTS idx_lb_hof
  ON public.leaderboard_weekly (is_hall_of_fame, world) WHERE is_hall_of_fame = true;

ALTER TABLE public.leaderboard_weekly ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS lb_read ON public.leaderboard_weekly;
CREATE POLICY lb_read ON public.leaderboard_weekly FOR SELECT USING (true);
DROP POLICY IF EXISTS lb_write ON public.leaderboard_weekly;
CREATE POLICY lb_write ON public.leaderboard_weekly
  FOR ALL USING (true) WITH CHECK (true);

-- K5 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guild_quests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guild_id     text NOT NULL,             -- Referenz auf guilds.id
  week_start   date NOT NULL,
  title        text NOT NULL,
  description  text,
  target_xp    int NOT NULL DEFAULT 500,
  current_xp   int NOT NULL DEFAULT 0,
  completed_at timestamptz,
  reward_xp    int NOT NULL DEFAULT 100,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (guild_id, week_start)
);

CREATE INDEX IF NOT EXISTS idx_guild_quests_guild_week
  ON public.guild_quests (guild_id, week_start DESC);

ALTER TABLE public.guild_quests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS gq_read ON public.guild_quests;
CREATE POLICY gq_read ON public.guild_quests FOR SELECT USING (true);
DROP POLICY IF EXISTS gq_write ON public.guild_quests;
CREATE POLICY gq_write ON public.guild_quests
  FOR ALL USING (true) WITH CHECK (true);

-- K6 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.destiny_weekly_draws (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  week_start   date NOT NULL,
  card_id      text NOT NULL,
  drawn_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, week_start)
);

CREATE INDEX IF NOT EXISTS idx_destiny_user_week
  ON public.destiny_weekly_draws (user_id, week_start DESC);

ALTER TABLE public.destiny_weekly_draws ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS dwd_own ON public.destiny_weekly_draws;
CREATE POLICY dwd_own ON public.destiny_weekly_draws
  FOR ALL USING (true) WITH CHECK (true);

COMMENT ON COLUMN public.user_achievements.tier IS 'Bronze/Silver/Gold/Platinum (K1).';
COMMENT ON TABLE public.daily_challenges_active IS 'Tägliche Welt-Challenges (K2).';
COMMENT ON TABLE public.leaderboard_weekly IS 'Wochen-Leaderboards + Hall of Fame (K3).';
COMMENT ON TABLE public.guild_quests IS 'Wöchentliche Guild-Gruppen-Quests (K5).';
COMMENT ON TABLE public.destiny_weekly_draws IS 'Auto-Ziehung jeden Sonntag (K6).';
