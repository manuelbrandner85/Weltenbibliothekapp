-- ======================================================================
-- MIGRATION v113 -- research_pins UPDATE-Haertung via Vote-Trigger
-- ======================================================================
--
-- Problem: pins_update_own hatte USING(true)/WITH CHECK(true) weil der
-- Vote-Aggregat-Writer (Voter != Pin-Owner) upvotes/downvotes zurueck-
-- schreibt. Direkter Client-Update war noetig, liess aber jeden beliebigen
-- Wert in alle Felder schreiben.
--
-- Loesung:
--   1) SECURITY DEFINER Trigger-Funktion trg_recompute_pin_votes():
--      Bei INSERT/UPDATE/DELETE auf user_research_pin_votes wird der
--      Aggregat (upvotes/downvotes) automatisch neu berechnet. Der
--      Client muss user_research_pins nicht mehr anfassen.
--   2) pins_update_own auf auth.uid()::text = user_id haerten:
--      Nur noch der Pin-Owner kann seinen Pin bearbeiten (Titel, Beschr.,
--      is_archived). Der Trigger laeuft mit Owner-Rechten und umgeht RLS.
--   3) pins_insert ebenfalls haerten: Jeder eingeloggte User kann einen
--      eigenen Pin anlegen. Anon-Insert war zu offen.
--
-- Client-seitig: Aggregat-Sync-Block in research_pin_service.dart entfernt
-- (uebernimmt jetzt der Trigger). Vote-Upsert bleibt, aber kein folgendes
-- .update() auf user_research_pins mehr.
--
-- Idempotent.
-- ======================================================================

-- ─────────────────────────────────────────────────────────────────────
-- 1) Trigger-Funktion: Vote-Aggregat automatisch aktualisieren
-- ─────────────────────────────────────────────────────────────────────
create or replace function public.trg_recompute_pin_votes()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
as $$
declare
  v_pin_id uuid;
begin
  -- Betroffene pin_id aus dem alten oder neuen Row lesen
  if tg_op = 'DELETE' then
    v_pin_id := old.pin_id;
  else
    v_pin_id := new.pin_id;
  end if;

  update public.user_research_pins
  set
    upvotes   = (select count(*) from public.user_research_pin_votes where pin_id = v_pin_id and vote = 1),
    downvotes = (select count(*) from public.user_research_pin_votes where pin_id = v_pin_id and vote = -1),
    updated_at = now()
  where id = v_pin_id;

  return null; -- AFTER-Trigger, Rueckgabewert wird ignoriert
end;
$$;

-- Trigger auf user_research_pin_votes anlegen (idempotent via drop-first)
drop trigger if exists pin_votes_recompute on public.user_research_pin_votes;
create trigger pin_votes_recompute
  after insert or update or delete on public.user_research_pin_votes
  for each row execute function public.trg_recompute_pin_votes();

-- ─────────────────────────────────────────────────────────────────────
-- 2) pins_update_own: nur noch Pin-Owner darf updaten
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists pins_update_own on public.user_research_pins;
create policy pins_update_own on public.user_research_pins
  for update to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 3) pins_insert: nur authentifizierte User fuer eigene Pins
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists pins_insert on public.user_research_pins;
create policy pins_insert on public.user_research_pins
  for insert to public
  with check (auth.uid()::text = user_id);
