#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 🔐 Release-Keystore für Weltenbibliothek erzeugen (einmalig!)
# ---------------------------------------------------------------------------
# Erzeugt android/app/weltenbibliothek.jks + gibt die GitHub-Secrets aus,
# die in Repo-Settings → Secrets and variables → Actions eingetragen werden müssen.
#
# WICHTIG:
#   • Keystore NIEMALS committen (ist in android/.gitignore).
#   • Keystore + Passwörter sicher sichern (Passwort-Manager). Verlust = nie
#     wieder Over-the-Top-Updates möglich, User müssten neu installieren.
# ---------------------------------------------------------------------------

set -euo pipefail

KEYSTORE_PATH="android/app/weltenbibliothek.jks"
ALIAS="weltenbibliothek"
VALIDITY_DAYS=10000   # ~27 Jahre — App-Lebensdauer abdecken

if [ -f "$KEYSTORE_PATH" ]; then
  echo "⚠️  $KEYSTORE_PATH existiert bereits. Abbruch (nicht überschreiben!)."
  echo "   Wenn du WIRKLICH neu erzeugen willst: erst Datei löschen."
  exit 1
fi

read -rsp "🔒 Store-Passwort (mind. 6 Zeichen): " STORE_PASS
echo
read -rsp "🔒 Store-Passwort bestätigen: " STORE_PASS_CONFIRM
echo
if [ "$STORE_PASS" != "$STORE_PASS_CONFIRM" ]; then
  echo "❌ Passwörter stimmen nicht überein." >&2
  exit 1
fi

read -rsp "🔑 Key-Passwort (kann identisch zum Store-Passwort sein): " KEY_PASS
echo

keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 \
  -validity "$VALIDITY_DAYS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=Weltenbibliothek, OU=App, O=Weltenbibliothek, L=Vienna, ST=Vienna, C=AT"

echo
echo "✅ Keystore erzeugt: $KEYSTORE_PATH"
echo
echo "───────────────────────────────────────────────────────────────"
echo "📋 Folgende GitHub-Secrets im Repo anlegen"
echo "   (Settings → Secrets and variables → Actions → New secret):"
echo "───────────────────────────────────────────────────────────────"
echo
echo "ANDROID_KEYSTORE_BASE64:"
base64 -w 0 "$KEYSTORE_PATH"
echo
echo
echo "ANDROID_KEYSTORE_PASSWORD: $STORE_PASS"
echo "ANDROID_KEY_ALIAS:         $ALIAS"
echo "ANDROID_KEY_PASSWORD:      $KEY_PASS"
echo
echo "───────────────────────────────────────────────────────────────"
echo "💾 Keystore sichern: android/app/weltenbibliothek.jks + Passwörter"
echo "   in Passwort-Manager / Offline-Backup kopieren. NIE committen!"
echo "───────────────────────────────────────────────────────────────"
