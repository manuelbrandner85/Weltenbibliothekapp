---
name: shorebird-ota-workflow
description: Shorebird OTA Update-Regeln für Weltenbibliothek
globs: ["pubspec.yaml", "lib/**", ".github/workflows/shorebird_*"]
---

# Shorebird OTA Workflow – Weltenbibliothek

## Entscheidungsbaum
1. Ist die Änderung rein Dart (UI, Logik, Bugfix)?
   → shorebird patch (automatisch via CI bei main-Push)
   → Build-Nummer in pubspec.yaml NICHT ändern
2. Betrifft die Änderung native Teile (Plugin, Permission, Kotlin)?
   → WARNUNG: "Neuer Release nötig!"
   → Build-Nummer MUSS erhöht werden (strikt aufsteigend)
   → shorebird release android (nur manuell triggern)

## Regeln
- Patches gehen nur an latest Release-Version
- Ältere APKs → ReleaseUpdateScreen → In-App-Download
- app_config.min_version wird automatisch via CI gesetzt
- Signatur-Mismatch-Schutz: Nach 2 fehlgeschlagenen Installs → Notausgang
- NIEMALS version: in pubspec.yaml ändern ohne explizite Freigabe

## CI-Workflows
- shorebird_patch.yml: Feuert bei JEDEM main-Push
- build_apk.yml: Nur manuell, setzt min_version automatisch
- sync_app_config.yml: UPSERT mit ?on_conflict=platform
- apply_migrations.yml: SQL-Migrationen bei jedem main-Push
- deploy_worker.yml: Worker-Deploy bei workers/** Änderung
