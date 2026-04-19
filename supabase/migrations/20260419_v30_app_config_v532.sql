-- ============================================================
-- v30: app_config auf v5.32.0 aktualisieren
-- ============================================================
UPDATE public.app_config
SET
  latest_version    = '5.32.0',
  min_version       = '5.32.0',
  apk_download_url  = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.32.0/weltenbibliothek-v5.32.0-universal.apk',
  changelog         = '• Chat: Nachrichten senden für alle Nutzer (kein Login nötig)' || chr(10) ||
                      '• Kompatibilität: ältere Android-Geräte (32-bit ARM) unterstützt' || chr(10) ||
                      '• Android 5.0+ (API 21) wird unterstützt' || chr(10) ||
                      '• Automatische anonyme Session beim App-Start' || chr(10) ||
                      '• Nachrichtenanzeige: Race-Condition behoben' || chr(10) ||
                      '• Verbesserte Fehlermeldungen im Chat',
  release_notes_url = 'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.32.0',
  updated_at        = NOW()
WHERE platform = 'android';
