-- v138: Tool-Bau-Freigabe durch Root-Admin.
--
-- Einfache Admins duerfen jetzt Tools bauen/erweitern lassen, aber die Anfrage
-- geht zuerst zur Root-Admin-Freigabe (status 'pending_approval'). Erst nach
-- Freigabe wird das GitHub-Issue erstellt und gebaut.
--
-- 1. Status-CHECK um 'pending_approval' erweitern.
-- 2. Spalten mode/target/spec ergaenzen, damit der Root-Admin bei Freigabe
--    genau das angefragte Tool (inkl. KI-Spezifikation) bauen lassen kann.

ALTER TABLE tool_requests DROP CONSTRAINT IF EXISTS tool_requests_status_check;

ALTER TABLE tool_requests
  ADD CONSTRAINT tool_requests_status_check
  CHECK (status IN ('open', 'pending_approval', 'issue_created', 'done', 'rejected'));

ALTER TABLE tool_requests ADD COLUMN IF NOT EXISTS mode   text;
ALTER TABLE tool_requests ADD COLUMN IF NOT EXISTS target text;
ALTER TABLE tool_requests ADD COLUMN IF NOT EXISTS spec   text;
