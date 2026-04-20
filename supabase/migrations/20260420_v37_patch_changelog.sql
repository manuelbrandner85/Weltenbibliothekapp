-- Phase 1b: patch_changelog Spalte in app_config
-- Speichert den automatisch generierten Changelog des letzten Shorebird-OTA-Patches.
-- Wird von shorebird_patch.yml nach erfolgreichem Patch-Upload befüllt.
-- PatchReadyDialog liest diesen Wert und zeigt ihn dem User.

ALTER TABLE public.app_config
  ADD COLUMN IF NOT EXISTS patch_changelog TEXT;
