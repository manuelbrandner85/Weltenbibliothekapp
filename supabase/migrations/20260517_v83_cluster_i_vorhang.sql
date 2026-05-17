-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v83 – Cluster I: Vorhang-Features
--
-- I1 vorhang_lesson_notes: persönliche Notizen pro Lektion
-- I3 branch_boss_tests:    Boss-Tests pro Branch (15 Fragen)
-- I4 Shadow-Journal:       BLEIBT LOKAL (kein Server-Sync — Privacy).
-- ═══════════════════════════════════════════════════════════════

-- I1 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vorhang_lesson_notes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  module_code  text NOT NULL,            -- z.B. 'V-03'
  body         text NOT NULL,
  tags         text[] NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, module_code)
);

CREATE INDEX IF NOT EXISTS idx_lesson_notes_user
  ON public.vorhang_lesson_notes (user_id, updated_at DESC);

ALTER TABLE public.vorhang_lesson_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notes_own ON public.vorhang_lesson_notes;
CREATE POLICY notes_own ON public.vorhang_lesson_notes
  FOR ALL USING (true) WITH CHECK (true);


-- I3 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vorhang_branch_boss_tests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch       text NOT NULL UNIQUE,     -- 'Machtpsychologie' etc.
  title        text NOT NULL,
  description  text,
  questions    jsonb NOT NULL,           -- [{q, options[], correct, explanation}, ...]
  pass_pct     smallint NOT NULL DEFAULT 80,
  xp_reward    smallint NOT NULL DEFAULT 300,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.vorhang_branch_boss_tests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS boss_read ON public.vorhang_branch_boss_tests;
CREATE POLICY boss_read ON public.vorhang_branch_boss_tests
  FOR SELECT USING (true);

CREATE TABLE IF NOT EXISTS public.vorhang_branch_boss_attempts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       text NOT NULL,
  branch        text NOT NULL,
  score_pct     smallint NOT NULL,
  passed        boolean NOT NULL,
  details       jsonb,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_boss_att_user_branch
  ON public.vorhang_branch_boss_attempts (user_id, branch, created_at DESC);

ALTER TABLE public.vorhang_branch_boss_attempts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS boss_att_own ON public.vorhang_branch_boss_attempts;
CREATE POLICY boss_att_own ON public.vorhang_branch_boss_attempts
  FOR ALL USING (true) WITH CHECK (true);

-- Seed: minimal 1 Boss-Test pro Branch als Platzhalter (3 Fragen, lasse
-- für Content-Editor in der App expandieren).
INSERT INTO public.vorhang_branch_boss_tests (branch, title, description, questions, pass_pct, xp_reward)
SELECT * FROM (VALUES
  ('Machtpsychologie', 'Boss: Machtpsychologie',
   'Du hast die 5 Module dieser Branch geschafft. Zeig, dass du das Wesen der Macht verstanden hast.',
   '[
     {"q":"Was unterscheidet Macht von Autorität?","options":["Macht ist legitim, Autorität nicht","Autorität ist anerkannte Macht","Sie sind identisch","Macht ist nur körperlich"],"correct":1,"explanation":"Autorität = Macht + Legitimität."},
     {"q":"Welche Form von Macht beruht auf Belohnung?","options":["Zwangsmacht","Belohnungsmacht","Expertenmacht","Referenzmacht"],"correct":1,"explanation":"French & Raven, klassische Typologie."},
     {"q":"Robert Greene nennt das wichtigste Gesetz:","options":["Überstrahle niemals den Meister","Vertraue niemandem","Sei immer freundlich","Verberge deine Gedanken"],"correct":0,"explanation":"48 Laws of Power, Gesetz 1."}
   ]'::jsonb, 80::smallint, 300::smallint),
  ('Manipulationserkennung', 'Boss: Manipulationserkennung',
   'Erkenne die Muster.', '[]'::jsonb, 80::smallint, 300::smallint),
  ('Verhandlung & Überzeugung', 'Boss: Verhandlung',
   'Vom Anker zur Win-Win.', '[]'::jsonb, 80::smallint, 300::smallint),
  ('Körpersprache & Nonverbales', 'Boss: Körpersprache',
   'Lies den Körper.', '[]'::jsonb, 80::smallint, 300::smallint),
  ('Strategisches Denken', 'Boss: Strategie',
   'Mehrere Züge voraus.', '[]'::jsonb, 80::smallint, 300::smallint),
  ('Schattenarbeit', 'Boss: Schatten',
   'Was du im Schatten hältst, hält dich.', '[]'::jsonb, 80::smallint, 300::smallint)
) AS v(branch, title, description, questions, pass_pct, xp_reward)
WHERE NOT EXISTS (
  SELECT 1 FROM public.vorhang_branch_boss_tests WHERE vorhang_branch_boss_tests.branch = v.branch
);

COMMENT ON TABLE public.vorhang_lesson_notes IS 'Notizen pro Modul, sync (I1).';
COMMENT ON TABLE public.vorhang_branch_boss_tests IS 'Boss-Tests pro Branch (I3).';
