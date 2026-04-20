-- ============================================================
-- v34: app_config auf v5.34.0 aktualisieren
-- ============================================================
-- Test-Release: Signatur-Kompatibilität v5.33.0 → v5.34.0 prüfen.
-- Beide APKs sind mit demselben persistenten Release-Keystore signiert
-- → Over-the-top-Install ohne "App nicht installiert".
-- ============================================================
UPDATE public.app_config
SET
  latest_version    = '5.34.0',
  min_version       = '5.33.0',
  apk_download_url  = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.34.0/weltenbibliothek-v5.34.0-universal.apk',
  changelog         = '• Signatur-Update: APK-Updates ohne Deinstallation (persistent Keystore)' || chr(10) ||
                      '• Update-Benachrichtigung sofort nach Download' || chr(10) ||
                      '• Chat & Community Fixes',
  release_notes_url = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.34.0',
  updated_at        = NOW()
WHERE platform = 'android';
