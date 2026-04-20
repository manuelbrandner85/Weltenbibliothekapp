-- ============================================================
-- v33: Silent-Patch-Modus für v5.32.0-User
-- ============================================================
-- Problem: v5.32.0 APK wurde ohne persistenten Keystore gebaut (Debug-Key).
--          v5.33.0 APK ist mit neuem Release-Keystore signiert.
--          → User bekommen "App nicht installiert" beim APK-Update.
--
-- Lösung: latest_version + min_version zurück auf 5.32.0.
--         v5.32.0-User sehen KEINEN Update-Dialog, bekommen Fixes
--         stattdessen unsichtbar via Shorebird OTA-Patch.
--         Ab v5.33.0 ist alles mit demselben Key signiert → künftige
--         APK-Updates laufen sauber.
-- ============================================================
UPDATE public.app_config
SET
  latest_version    = '5.32.0',
  min_version       = '5.32.0',
  apk_download_url  = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.33.0/weltenbibliothek-v5.33.0-universal.apk',
  changelog         = '(Silent-Patch-Modus für v5.32.0-User — Fixes via Shorebird OTA)',
  release_notes_url = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.33.0',
  updated_at        = NOW()
WHERE platform = 'android';
