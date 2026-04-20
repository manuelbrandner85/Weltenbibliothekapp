-- ============================================================
-- v35: app_config auf v5.35.0 aktualisieren
-- ============================================================
-- Release v5.35.0 — Storage-Migration Hive → SharedPreferences + SQLite.
--
-- Neue native Android-Libs (sqflite + path) → kein Shorebird-OTA möglich,
-- neuer APK-Release ist Pflicht.
--
-- APK ist mit demselben persistenten Release-Keystore signiert wie v5.34.0
-- → Over-the-top-Install ohne "App nicht installiert".
--
-- WICHTIG: Erst nach Veröffentlichung des GitHub-Releases v5.35.0 ausführen!
--          Sonst sehen User einen toten Download-Link.
-- ============================================================
UPDATE public.app_config
SET
  latest_version    = '5.35.0',
  min_version       = '5.34.0',
  apk_download_url  = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.35.0/weltenbibliothek-v5.35.0-universal.apk',
  changelog         = '• Storage komplett migriert: SharedPreferences + SQLite (statt Hive)' || chr(10) ||
                      '• Stabilere Chat-Persistenz (keine "Box not found"-Fehler mehr)' || chr(10) ||
                      '• Schnellere App-Starts' || chr(10) ||
                      '• Diverse Bugfixes',
  release_notes_url = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.35.0',
  updated_at        = NOW()
WHERE platform = 'android';
