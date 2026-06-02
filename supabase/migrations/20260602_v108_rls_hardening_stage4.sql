-- ══════════════════════════════════════════════════════════════════════════
-- MIGRATION v108 -- RLS-Haertung Stufe 4 (Advisor-ERROR + Storage-Listing)
-- ══════════════════════════════════════════════════════════════════════════
--
-- Behebt die niedrig-riskanten, klar abgegrenzten Advisor-Befunde:
--
--   1) ERROR security_definer_view: View public.edge_confidence_aggregate
--      lief mit SECURITY DEFINER (umgeht RLS der Basistabelle). Die View ist
--      rein aggregierend (count/avg pro Kante, kein user_id im Output) und die
--      Basistabelle user_edge_confidence hat edge_conf_read SELECT USING(true).
--      Umstellung auf security_invoker => identische Ergebnisse, kein
--      RLS-Bypass mehr. Client nutzt die View (edge_confidence_service.dart).
--
--   2) WARN public_bucket_allows_listing: avatars_public_read / media_public_read
--      erlaubten Object-Listing (Enumeration) auf storage.objects. Beide Buckets
--      sind public=true -> getPublicUrl funktioniert ohne SELECT-Policy. Im
--      gesamten Repo gibt es KEIN .list() auf Storage. Entfernen schliesst die
--      Enumeration ohne legitime Flows (Upload/getPublicUrl/remove) zu brechen.
--
-- Idempotent durchfuehrbar.
-- ══════════════════════════════════════════════════════════════════════════

-- 1) SECURITY DEFINER View entschaerfen (PG15+: security_invoker)
alter view public.edge_confidence_aggregate set (security_invoker = on);

-- 2) Storage-Listing auf public Buckets entfernen (Object-URLs bleiben nutzbar)
drop policy if exists avatars_public_read on storage.objects;
drop policy if exists media_public_read on storage.objects;
