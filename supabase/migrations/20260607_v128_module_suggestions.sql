-- v128 (2026-06-07): Tabellen fuer die KI-Modul-Werkstatt-Automatik.
--
-- module_suggestions: KI-generierte Vorschlaege (neue Module, Verbesserungen,
--   Qualitaets-Findings), die im Admin-Dashboard zur Bestaetigung anstehen.
-- tool_requests: Anfragen fuer neue interaktive Tools (LOGIK-Module), die ein
--   App-Update brauchen -- werden als GitHub-Issue weitergeleitet.
--
-- Sicherheit: BEIDE Tabellen haben RLS aktiviert, aber KEINE permissiven
-- Policies. Zugriff ausschliesslich ueber den Cloudflare-Worker mit
-- service_role-Key (umgeht RLS). Kein Client liest/schreibt direkt.

-- ─────────────────────────────────────────────────────────────────────────
-- module_suggestions
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS module_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  world text NOT NULL CHECK (world IN ('vorhang', 'ursprung')),
  -- 'new'     = komplett neues Modul vorgeschlagen
  -- 'improve' = Verbesserung eines bestehenden Moduls (target_module_code gesetzt)
  -- 'quality' = Qualitaets-Finding (quality_findings gesetzt, kein Inhalt)
  kind text NOT NULL CHECK (kind IN ('new', 'improve', 'quality')),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected')),
  -- Bei improve/quality: auf welches bestehende Modul bezieht sich der Vorschlag
  target_module_code text,
  -- Vorgeschlagener Modul-Inhalt (bei new/improve)
  title text,
  subtitle text,
  branch text,
  theory_content text,
  case_study text,
  exercise_description text,
  xp_reward int,
  -- Bei quality: Liste der gefundenen Probleme (jsonb-Array von Strings)
  quality_findings jsonb,
  -- KI-Begruendung warum dieser Vorschlag sinnvoll ist (Klartext fuer Admin)
  rationale text,
  created_by text DEFAULT 'workshop-ai',
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by text
);

CREATE INDEX IF NOT EXISTS idx_module_suggestions_pending
  ON module_suggestions (world, status, created_at DESC);

ALTER TABLE module_suggestions ENABLE ROW LEVEL SECURITY;
-- Bewusst KEINE Policy: nur service_role (Worker) hat Zugriff.

-- ─────────────────────────────────────────────────────────────────────────
-- tool_requests (Vorschlag D: Bruecke zu Claude Code fuer LOGIK-Module)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tool_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  world text,
  title text NOT NULL,
  description text NOT NULL,
  -- 'open' = angefragt, 'issue_created' = GitHub-Issue erstellt,
  -- 'done' = umgesetzt, 'rejected' = verworfen
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'issue_created', 'done', 'rejected')),
  github_issue_url text,
  requested_by text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tool_requests_status
  ON tool_requests (status, created_at DESC);

ALTER TABLE tool_requests ENABLE ROW LEVEL SECURITY;
-- Bewusst KEINE Policy: nur service_role (Worker) hat Zugriff.
