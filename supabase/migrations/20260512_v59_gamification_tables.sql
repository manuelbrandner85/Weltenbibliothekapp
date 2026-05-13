-- ══════════════════════════════════════════════════════════════════════════════
-- v59 — OCTALYSIS GAMIFICATION SYSTEM
-- Skill-Tree, Artefakte, Titel, Schicksalskarten
-- Welten: materie, energie, noir, genesis
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. USER_SKILL_TREE ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_skill_tree (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  world       TEXT NOT NULL CHECK (world IN ('materie', 'energie', 'noir', 'genesis')),
  skill_key   TEXT NOT NULL,           -- z.B. 'recherche_1', 'meditation_2'
  level       INT  NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 10),
  xp          INT  NOT NULL DEFAULT 0 CHECK (xp >= 0),
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, world, skill_key)
);

CREATE INDEX IF NOT EXISTS idx_skill_tree_user   ON public.user_skill_tree (user_id);
CREATE INDEX IF NOT EXISTS idx_skill_tree_world  ON public.user_skill_tree (user_id, world);

-- ── 2. ARTIFACTS ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.artifacts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT NOT NULL UNIQUE,     -- z.B. 'materie_lupe_der_wahrheit'
  world       TEXT NOT NULL CHECK (world IN ('materie', 'energie', 'noir', 'genesis', 'universal')),
  name_de     TEXT NOT NULL,
  description_de TEXT NOT NULL,
  rarity      TEXT NOT NULL CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')) DEFAULT 'common',
  icon_emoji  TEXT NOT NULL DEFAULT '🔮',
  xp_bonus    INT  NOT NULL DEFAULT 0,
  effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_artifacts_world  ON public.artifacts (world);
CREATE INDEX IF NOT EXISTS idx_artifacts_rarity ON public.artifacts (rarity);

-- ── 3. USER_ARTIFACTS ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_artifacts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artifact_id UUID NOT NULL REFERENCES public.artifacts(id) ON DELETE CASCADE,
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_equipped BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (user_id, artifact_id)
);

CREATE INDEX IF NOT EXISTS idx_user_artifacts_user ON public.user_artifacts (user_id);

-- ── 4. USER_TITLES ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_titles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title_key   TEXT NOT NULL,           -- z.B. 'novize', 'forscher_meister'
  title_de    TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active   BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (user_id, title_key)
);

CREATE INDEX IF NOT EXISTS idx_user_titles_user ON public.user_titles (user_id);

-- ── 5. DAILY_DESTINY_CARDS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_destiny_cards (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  card_type   TEXT NOT NULL CHECK (card_type IN ('wisdom', 'challenge', 'boost', 'mystery')),
  card_index  INT  NOT NULL,           -- Index im Pool (0-59)
  title_de    TEXT NOT NULL,
  message_de  TEXT NOT NULL,
  drawn_at    DATE NOT NULL DEFAULT CURRENT_DATE,
  redeemed    BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (user_id, drawn_at)            -- Max 1 Karte pro Tag
);

CREATE INDEX IF NOT EXISTS idx_destiny_user_date ON public.daily_destiny_cards (user_id, drawn_at DESC);

-- ── UPDATED_AT TRIGGERS ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_skill_tree_updated_at') THEN
    CREATE TRIGGER trg_skill_tree_updated_at
      BEFORE UPDATE ON public.user_skill_tree
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END$$;

-- ══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════════════════════════════════

-- user_skill_tree
ALTER TABLE public.user_skill_tree ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "skill_tree_select_own" ON public.user_skill_tree;
DROP POLICY IF EXISTS "skill_tree_insert_own" ON public.user_skill_tree;
DROP POLICY IF EXISTS "skill_tree_update_own" ON public.user_skill_tree;
DROP POLICY IF EXISTS "skill_tree_delete_own" ON public.user_skill_tree;
CREATE POLICY "skill_tree_select_own" ON public.user_skill_tree FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "skill_tree_insert_own" ON public.user_skill_tree FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skill_tree_update_own" ON public.user_skill_tree FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "skill_tree_delete_own" ON public.user_skill_tree FOR DELETE USING (auth.uid() = user_id);

-- artifacts (öffentlich lesbar, nur Admin schreibbar)
ALTER TABLE public.artifacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "artifacts_select_all" ON public.artifacts;
CREATE POLICY "artifacts_select_all" ON public.artifacts FOR SELECT USING (true);

-- user_artifacts
ALTER TABLE public.user_artifacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_artifacts_select_own" ON public.user_artifacts;
DROP POLICY IF EXISTS "user_artifacts_insert_own" ON public.user_artifacts;
DROP POLICY IF EXISTS "user_artifacts_update_own" ON public.user_artifacts;
DROP POLICY IF EXISTS "user_artifacts_delete_own" ON public.user_artifacts;
CREATE POLICY "user_artifacts_select_own" ON public.user_artifacts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_artifacts_insert_own" ON public.user_artifacts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_artifacts_update_own" ON public.user_artifacts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "user_artifacts_delete_own" ON public.user_artifacts FOR DELETE USING (auth.uid() = user_id);

-- user_titles
ALTER TABLE public.user_titles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_titles_select_own" ON public.user_titles;
DROP POLICY IF EXISTS "user_titles_insert_own" ON public.user_titles;
DROP POLICY IF EXISTS "user_titles_update_own" ON public.user_titles;
DROP POLICY IF EXISTS "user_titles_delete_own" ON public.user_titles;
CREATE POLICY "user_titles_select_own" ON public.user_titles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_titles_insert_own" ON public.user_titles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_titles_update_own" ON public.user_titles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "user_titles_delete_own" ON public.user_titles FOR DELETE USING (auth.uid() = user_id);

-- daily_destiny_cards
ALTER TABLE public.daily_destiny_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "destiny_select_own" ON public.daily_destiny_cards;
DROP POLICY IF EXISTS "destiny_insert_own" ON public.daily_destiny_cards;
DROP POLICY IF EXISTS "destiny_update_own" ON public.daily_destiny_cards;
CREATE POLICY "destiny_select_own" ON public.daily_destiny_cards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "destiny_insert_own" ON public.daily_destiny_cards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "destiny_update_own" ON public.daily_destiny_cards FOR UPDATE USING (auth.uid() = user_id);

-- ── GRANTS ─────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_skill_tree    TO authenticated;
GRANT SELECT                         ON public.artifacts          TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_artifacts     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_titles        TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.daily_destiny_cards TO authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- SEED: 20 ARTEFAKTE (4 pro Welt × 5 Welten inkl. universal)
-- ══════════════════════════════════════════════════════════════════════════════

INSERT INTO public.artifacts (key, world, name_de, description_de, rarity, icon_emoji, xp_bonus, effect_json)
VALUES
  -- ── MATERIE (Fakten, Recherche, Wissenschaft) ──
  ('materie_lupe_der_wahrheit', 'materie',
   'Lupe der Wahrheit', 'Ein geschliffenes Kristallglas, das verborgene Zusammenhänge in Dokumenten sichtbar macht. Forscher schwören auf seine Klarheit.',
   'common', '🔍', 5, '{"skill_boost": "recherche", "bonus_pct": 10}'::jsonb),

  ('materie_kodex_der_fakten', 'materie',
   'Kodex der Fakten', 'Ein uraltes Buch, dessen Seiten sich selbst aktualisieren. Es enthält nur verifizierte Wahrheiten.',
   'rare', '📖', 15, '{"skill_boost": "faktencheck", "bonus_pct": 15}'::jsonb),

  ('materie_quantenkompass', 'materie',
   'Quantenkompass', 'Zeigt nicht nach Norden, sondern zur nächsten unentdeckten Erkenntnis. Vibriert bei Annäherung an die Wahrheit.',
   'epic', '🧭', 30, '{"skill_boost": "recherche", "bonus_pct": 25, "unlock_deep_search": true}'::jsonb),

  ('materie_teslas_notizbuch', 'materie',
   'Teslas verlorenes Notizbuch', 'Die letzten unveröffentlichten Notizen des Genies. Wer darin liest, versteht Muster, die anderen verborgen bleiben.',
   'legendary', '⚡', 50, '{"skill_boost": "all", "bonus_pct": 30, "title_unlock": "Hüter des Wissens"}'::jsonb),

  -- ── ENERGIE (Heilung, Bewusstsein, Spiritualität) ──
  ('energie_heilkristall', 'energie',
   'Heilkristall von Avalon', 'Ein schimmernder Amethyst, der die feinstofflichen Energieströme seines Trägers harmonisiert.',
   'common', '💎', 5, '{"skill_boost": "meditation", "bonus_pct": 10}'::jsonb),

  ('energie_klangschale_om', 'energie',
   'Klangschale des OM', 'Ihre Schwingung erreicht 432 Hz — die Frequenz universeller Harmonie. Öffnet das Herzchakra.',
   'rare', '🔔', 15, '{"skill_boost": "heilung", "bonus_pct": 15}'::jsonb),

  ('energie_aura_spiegel', 'energie',
   'Spiegel der Aura', 'Zeigt die Energiesignatur des Betrachters in schillernden Farben. Kein Schatten bleibt verborgen.',
   'epic', '🪞', 30, '{"skill_boost": "bewusstsein", "bonus_pct": 25, "unlock_aura_view": true}'::jsonb),

  ('energie_smaragdtafel', 'energie',
   'Smaragdtafel des Hermes', 'Die mythische Tafel mit dem Schlüssel zur universellen Transmutation. „Wie oben, so unten."',
   'legendary', '🟢', 50, '{"skill_boost": "all", "bonus_pct": 30, "title_unlock": "Hüter der Energie"}'::jsonb),

  -- ── NOIR (Macht, Geopolitik, Strategie) ──
  ('noir_schachfigur_schatten', 'noir',
   'Schachfigur des Schattens', 'Ein König aus Obsidian, der die Züge des Gegners vorhersagt. Wer ihn hält, denkt drei Schritte voraus.',
   'common', '♟️', 5, '{"skill_boost": "strategie", "bonus_pct": 10}'::jsonb),

  ('noir_schwarzes_dossier', 'noir',
   'Das Schwarze Dossier', 'Enthält kompromittierende Wahrheiten über die Mächtigen. Jede Seite ist verschlüsselt.',
   'rare', '🗂️', 15, '{"skill_boost": "geopolitik", "bonus_pct": 15}'::jsonb),

  ('noir_ring_der_macht', 'noir',
   'Ring der verborgenen Macht', 'Geschmiedet im Feuer geheimer Logen. Sein Träger erkennt Manipulation auf den ersten Blick.',
   'epic', '💍', 30, '{"skill_boost": "manipulation_erkennung", "bonus_pct": 25, "unlock_power_map": true}'::jsonb),

  ('noir_allsehendes_auge', 'noir',
   'Das Allsehende Auge', 'Symbol ältester Machtstrukturen. Gewährt Einblick in die verborgenen Netzwerke der Welt.',
   'legendary', '👁️', 50, '{"skill_boost": "all", "bonus_pct": 30, "title_unlock": "Meister der Schatten"}'::jsonb),

  -- ── GENESIS (Ursprung, Schöpfung, Mysterien) ──
  ('genesis_samen_des_anfangs', 'genesis',
   'Samen des Anfangs', 'Ein goldener Samen, der das Potenzial allen Lebens in sich trägt. Pulsiert leise im Rhythmus des Universums.',
   'common', '🌱', 5, '{"skill_boost": "alchemie", "bonus_pct": 10}'::jsonb),

  ('genesis_mondsichel_amulett', 'genesis',
   'Mondsichel-Amulett', 'Geformt aus dem Licht des ersten Vollmonds. Verbindet seinen Träger mit den Zyklen der Schöpfung.',
   'rare', '🌙', 15, '{"skill_boost": "mythen", "bonus_pct": 15}'::jsonb),

  ('genesis_weltenbaum_splitter', 'genesis',
   'Splitter des Weltenbaums', 'Ein Stück Yggdrasils Rinde, warm und lebendig. Flüstert Geschichten von Welten jenseits unserer.',
   'epic', '🌳', 30, '{"skill_boost": "kosmologie", "bonus_pct": 25, "unlock_genesis_map": true}'::jsonb),

  ('genesis_stein_der_weisen', 'genesis',
   'Stein der Weisen', 'Der Gral der Alchemisten. Transmutation ist nicht Blei zu Gold — sondern Unwissen zu Erleuchtung.',
   'legendary', '🔴', 50, '{"skill_boost": "all", "bonus_pct": 30, "title_unlock": "Meister der Genesis"}'::jsonb),

  -- ── UNIVERSAL (Weltübergreifend) ──
  ('universal_feder_der_ma_at', 'universal',
   'Feder der Ma''at', 'Die ägyptische Feder der Gerechtigkeit. Wiegt das Herz gegen die Wahrheit auf.',
   'common', '🪶', 5, '{"skill_boost": "all", "bonus_pct": 5}'::jsonb),

  ('universal_bibliothekspass', 'universal',
   'Goldener Bibliothekspass', 'Gewährt Zugang zu den verbotenen Regalen der Weltenbibliothek. Nur die Würdigsten erhalten ihn.',
   'rare', '🎫', 15, '{"skill_boost": "all", "bonus_pct": 10, "unlock_secret_content": true}'::jsonb),

  ('universal_astrolabium', 'universal',
   'Astrolabium der Alten', 'Ein bronzenes Präzisionsinstrument, das die Positionen der Sterne und die Muster der Geschichte kartiert.',
   'epic', '⭐', 30, '{"skill_boost": "all", "bonus_pct": 20}'::jsonb),

  ('universal_akasha_chronik', 'universal',
   'Schlüssel zur Akasha-Chronik', 'Öffnet das kosmische Gedächtnis — jeder Gedanke, jede Tat, jede Möglichkeit seit Anbeginn der Zeit.',
   'legendary', '🔑', 50, '{"skill_boost": "all", "bonus_pct": 35, "title_unlock": "Wächter der Akasha"}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ── REALTIME (idempotent) ──────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM realtime.subscription
    WHERE entity = 'public.user_skill_tree'
    LIMIT 1
  ) THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.user_skill_tree;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM realtime.subscription
    WHERE entity = 'public.user_artifacts'
    LIMIT 1
  ) THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.user_artifacts;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM realtime.subscription
    WHERE entity = 'public.daily_destiny_cards'
    LIMIT 1
  ) THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_destiny_cards;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
END$$;
