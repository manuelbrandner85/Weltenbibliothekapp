-- ============================================================
-- v32: app_config auf v5.33.0 aktualisieren
-- ============================================================
-- Erstmals signiert mit persistentem Release-Keystore →
-- User können direkt über alte APK drüber-installieren (kein Löschen nötig).
-- ============================================================
UPDATE public.app_config
SET
  latest_version    = '5.33.0',
  min_version       = '5.33.0',
  apk_download_url  = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.33.0/weltenbibliothek-v5.33.0-universal.apk',
  changelog         = '• Update-Benachrichtigung sofort nach Download (kein Neustart nötig)' || chr(10) ||
                      '• Alle Geräte werden zuverlässig über Updates informiert' || chr(10) ||
                      '• Chat: Nachrichten senden für alle Nutzer (kein Login nötig)' || chr(10) ||
                      '• Kompatibilität: ältere Android-Geräte (32-bit ARM) unterstützt' || chr(10) ||
                      '• Android 5.0+ (API 21) wird unterstützt' || chr(10) ||
                      '• Automatische anonyme Session beim App-Start',
  release_notes_url = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.33.0',
  updated_at        = NOW()
WHERE platform = 'android';
