-- ======================================================================
-- MIGRATION v112 -- Re-Apply von v108 (Stufe 4) -- Replay-Resilienz
-- ======================================================================
--
-- Befund: Die in v108 behobenen Advisor-Findings (security_definer_view
-- ERROR + 2x public_bucket_allows_listing) waren beim erneuten Advisor-
-- Lauf wieder aktiv. Ursache: vier aeltere Migrationen erstellen die
-- Bucket-Policies bzw. die View neu:
--   003_storage.sql, 20260402_v10_full_schema.sql,
--   20260504_v45_avatars_bucket.sql, 20260402_v3_v7_improvements.sql (Policies)
--   20260517_v77_research_pins_and_edge_confidence.sql (View)
-- Bei einem Migrations-Replay oder Storage-Re-Init gewinnen deren CREATE-
-- Statements, weil v108 nur DROPpt. Da v112 das spaeteste Datum traegt,
-- gewinnt dieser Re-Apply bei jedem geordneten Replay.
--
-- Identisch zu v108, hier zur Durchsetzung wiederholt.
-- Idempotent.
-- ======================================================================

-- 1) SECURITY DEFINER View entschaerfen (PG15+: security_invoker)
alter view public.edge_confidence_aggregate set (security_invoker = on);

-- 2) Storage-Listing auf public Buckets entfernen (Object-URLs bleiben nutzbar)
drop policy if exists avatars_public_read on storage.objects;
drop policy if exists media_public_read on storage.objects;
