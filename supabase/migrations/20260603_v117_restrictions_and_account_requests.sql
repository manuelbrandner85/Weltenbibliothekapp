-- v117: Granulare Sperren, Mute-Fix, Loesch-Blacklist und Antrags-Inbox
--
-- Behebt + ergaenzt das Moderations-System:
--   A) admin_mutes        -- fehlte komplett in Prod -> Mute-Inserts schlugen
--                            silent fehl. Jetzt angelegt.
--   B) user_restrictions  -- granulare, kategorisierte Sperren pro Scope
--                            (Chat, Livestream, Kommentare, XP, ...). Eine
--                            Zeile pro (user_id, scope). Befristet via
--                            expires_at oder permanent.
--   C) deleted_identities -- Blacklist geloeschter Nutzer. Verhindert
--                            Neuanmeldung mit gleichem Username/Namen/
--                            Geburtsdatum/-ort. Reaktivierung nur per Admin.
--   D) account_requests   -- vereinheitlichte Antrags-Inbox: Reaktivierung
--                            (nach Loeschung), Einspruch gegen Sperre,
--                            Selbst-Loeschung. Admin sieht offene Antraege.
--
-- Alle Tabellen: RLS aktiv. Admin/Mod (profiles.role) liest+schreibt,
-- service_role (Worker) darf alles, User sieht eigene Eintraege.
-- user_id ist TEXT (kompatibel mit UUID UND legacy InvisibleAuth user_<ts>).

-- ════════════════════════════════════════════════════════════════════════
-- A) admin_mutes -- Stummschaltungen (fehlte in Prod, Worker schrieb ins Leere)
-- ════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.admin_mutes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL UNIQUE,
  username        TEXT,
  muted_by        TEXT,
  reason          TEXT,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_mutes_user
  ON public.admin_mutes(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_mutes_expires
  ON public.admin_mutes(expires_at)
  WHERE expires_at IS NOT NULL;

ALTER TABLE public.admin_mutes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_mutes_read" ON public.admin_mutes;
CREATE POLICY "admin_mutes_read" ON public.admin_mutes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.uid()::text = user_id
  );

DROP POLICY IF EXISTS "admin_mutes_write" ON public.admin_mutes;
CREATE POLICY "admin_mutes_write" ON public.admin_mutes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- B) user_restrictions -- granulare, kategorisierte Sperren
-- ════════════════════════════════════════════════════════════════════════
-- scope-Werte (kategorisiert):
--   Kommunikation : 'chat', 'livestream', 'direct_messages', 'shadow_mute'
--   Content       : 'create_articles', 'create_pins', 'comment'
--   Gamification  : 'earn_xp'
--   Vollsperrung  : 'all'  (entspricht klassischem Ban)
CREATE TABLE IF NOT EXISTS public.user_restrictions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL,
  username        TEXT,
  scope           TEXT NOT NULL,
  reason          TEXT,
  created_by      TEXT,
  is_permanent    BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_restrictions_scope_chk CHECK (scope IN (
    'chat','livestream','direct_messages','shadow_mute',
    'create_articles','create_pins','comment',
    'earn_xp','all'
  )),
  CONSTRAINT user_restrictions_uniq UNIQUE (user_id, scope)
);

CREATE INDEX IF NOT EXISTS idx_user_restrictions_user
  ON public.user_restrictions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_restrictions_expires
  ON public.user_restrictions(expires_at)
  WHERE is_permanent = FALSE AND expires_at IS NOT NULL;

ALTER TABLE public.user_restrictions ENABLE ROW LEVEL SECURITY;

-- Betroffener User darf eigene Sperren sehen (fuer In-App-Anzeige + Einspruch).
DROP POLICY IF EXISTS "user_restrictions_read" ON public.user_restrictions;
CREATE POLICY "user_restrictions_read" ON public.user_restrictions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.uid()::text = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.legacy_user_id = user_id
    )
  );

DROP POLICY IF EXISTS "user_restrictions_write" ON public.user_restrictions;
CREATE POLICY "user_restrictions_write" ON public.user_restrictions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );

COMMENT ON TABLE public.user_restrictions IS
  'Granulare kategorisierte Sperren pro User+Scope. Schreiben via Worker (service_role). all=Vollsperre, shadow_mute=Nachrichten nur fuer User selbst sichtbar.';

-- ════════════════════════════════════════════════════════════════════════
-- C) deleted_identities -- Blacklist geloeschter Nutzer (Neuanmelde-Sperre)
-- ════════════════════════════════════════════════════════════════════════
-- Beim Hard-Delete eines Users werden hier die Identitaets-Merkmale
-- (lowercased) gespeichert. Bei Neuanmeldung prueft der Worker gegen diese
-- Tabelle. reactivation_status: 'blocked' -> 'requested' (User stellt Antrag)
-- -> 'approved' (Admin gibt frei, Eintrag wird beim naechsten Register
-- ignoriert) bzw. bleibt 'blocked'.
CREATE TABLE IF NOT EXISTS public.deleted_identities (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username_lower      TEXT,
  full_name_lower     TEXT,
  birth_date          DATE,
  birth_place_lower   TEXT,
  identity_hash       TEXT,
  original_user_id    TEXT,
  deleted_by          TEXT,
  reason              TEXT,
  reactivation_status TEXT NOT NULL DEFAULT 'blocked',
  deleted_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT deleted_identities_status_chk
    CHECK (reactivation_status IN ('blocked','requested','approved'))
);

CREATE INDEX IF NOT EXISTS idx_deleted_identities_username
  ON public.deleted_identities(username_lower);
CREATE INDEX IF NOT EXISTS idx_deleted_identities_hash
  ON public.deleted_identities(identity_hash);

ALTER TABLE public.deleted_identities ENABLE ROW LEVEL SECURITY;

-- Nur Admins lesen, nur service_role schreibt. Kein User-Zugriff (PII).
DROP POLICY IF EXISTS "deleted_identities_admin" ON public.deleted_identities;
CREATE POLICY "deleted_identities_admin" ON public.deleted_identities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );

COMMENT ON TABLE public.deleted_identities IS
  'Blacklist geloeschter Nutzer. Verhindert Neuanmeldung mit gleichem Username/Name/Geburtsdatum/-ort bis Admin reaktiviert.';

-- ════════════════════════════════════════════════════════════════════════
-- D) account_requests -- Antrags-Inbox (Reaktivierung / Einspruch / Selbstloesch)
-- ════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.account_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type              TEXT NOT NULL,
  user_id           TEXT,
  username          TEXT,
  full_name         TEXT,
  birth_date        DATE,
  birth_place       TEXT,
  restriction_scope TEXT,
  message           TEXT,
  status            TEXT NOT NULL DEFAULT 'pending',
  handled_by        TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  handled_at        TIMESTAMPTZ,
  CONSTRAINT account_requests_type_chk
    CHECK (type IN ('reactivation','appeal','self_deletion')),
  CONSTRAINT account_requests_status_chk
    CHECK (status IN ('pending','approved','rejected'))
);

CREATE INDEX IF NOT EXISTS idx_account_requests_status
  ON public.account_requests(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_account_requests_user
  ON public.account_requests(user_id);

ALTER TABLE public.account_requests ENABLE ROW LEVEL SECURITY;

-- User darf eigene Antraege sehen, Admin alle. Schreiben via Worker.
DROP POLICY IF EXISTS "account_requests_read" ON public.account_requests;
CREATE POLICY "account_requests_read" ON public.account_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.uid()::text = user_id
  );

DROP POLICY IF EXISTS "account_requests_write" ON public.account_requests;
CREATE POLICY "account_requests_write" ON public.account_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );

COMMENT ON TABLE public.account_requests IS
  'Antrags-Inbox: reactivation (nach Loeschung), appeal (Einspruch gegen Sperre), self_deletion (Selbst-Loeschung). Admin bearbeitet via Worker.';

-- ════════════════════════════════════════════════════════════════════════
-- E) notifications -- User darf eigene loeschen (bisher nur read + mark-read)
-- ════════════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "User kann eigene Notifications loeschen" ON public.notifications;
CREATE POLICY "User kann eigene Notifications loeschen" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);
