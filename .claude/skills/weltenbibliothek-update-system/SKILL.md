---
name: weltenbibliothek-update-system
description: Vollautomatisches Update-System (OTA + APK)
globs: ["lib/widgets/update_*", "lib/widgets/patch_*", "lib/screens/release_update_*", "lib/services/update_*"]
---

# Update-System (v5.36.0+)

## Shorebird OTA-Patches
- shorebird_code_push Package integriert, auto_update: true
- Patches automatisch im Hintergrund geladen
- PatchReadyDialog: Fullscreen-Dialog "Update bereit!"
- PatchDownloadIndicator: Dezenter Banner mit LinearProgress
- UpdateSuccessBanner: Grüner Banner nach erfolgreichem Update
- Stream-basiert: UpdateService.onPatchReady

## APK-Release-Updates
- app_config Tabelle: latest_version, min_version, apk_download_url
- ReleaseUpdateScreen: Fullscreen-Gate mit In-App-Download
- Signatur-Mismatch-Schutz: Notausgang nach 2 Fehlversuchen
- Auto-Retry-Countdown (60s) bei 404

## Auto-Restart (v5.37.0+, nativ)
- MainActivity.kt: MethodChannel weltenbibliothek/restart
- AlarmManager → Relaunch in 500ms → System.exit(0)
- Dart Fallback: SystemNavigator.pop

## Debug-Schutz
- APP_VERSION 0.0.0 → Release-Check komplett übersprungen
