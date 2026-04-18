-- ============================================================
-- WELTENBIBLIOTHEK v16 – FULL RESET + REBUILD
-- Datum: 2026-04-18
-- Projekt: adtviduaftdquvfjpojb
--
-- WARNUNG: Diese Migration LÖSCHT alles im public-Schema und
-- legt nur an, was Weltenbibliothek aktuell braucht.
--
-- Ausführen in:
-- https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new
--
-- Architektur-Entscheidungen:
-- * Keine User-Registration in der App → 2 System-Profile (1 pro Welt)
-- * profiles.id bleibt UUID, aber KEIN FK auf auth.users
-- * Chat-Schreiben läuft über Cloudflare Worker (Service-Role-Key)
-- * RLS-Policies erlauben anon Lesen, Schreiben nur service_role
-- ============================================================

-- ── PHASE A: WIPE ────────────────────────────────────────────
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA public TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;

-- ── PHASE B: EXTENSIONS ──────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── PHASE C: SHARED HELPERS ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;
