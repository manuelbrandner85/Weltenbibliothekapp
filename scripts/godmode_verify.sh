#!/usr/bin/env bash
# God-Mode Verify-Gate.
# Laeuft analyze + dart2js-Record-Guard + flutter build web.
# Schreibt bei Fehlern ALLE Ausgaben nach .godmode_verify_errors.log,
# damit der Auto-Fix-Schritt (Claude) die exakten Fehler lesen kann.
# Setzt .godmode_verify_ok auf "true" oder "false".
#
# Bewusst KEIN `set -e` -- wir wollen jeden Schritt durchlaufen und sammeln.

LOG=.godmode_verify_errors.log
: > "$LOG"
echo "false" > .godmode_verify_ok

fail() {
  echo "[VERIFY] FEHLGESCHLAGEN bei: $1" | tee -a "$LOG"
  echo "false" > .godmode_verify_ok
  exit 0
}

echo "[VERIFY] flutter pub get ..."
if ! flutter pub get >>"$LOG" 2>&1; then
  fail "flutter pub get"
fi

echo "[VERIFY] dart2js Record-Guard ..."
if ! python3 scripts/check_dart_records.py >>"$LOG" 2>&1; then
  fail "check_dart_records.py (Named Dart-3 Records gefunden -- crashen dart2js)"
fi

echo "[VERIFY] flutter analyze ..."
if ! flutter analyze --no-fatal-infos --no-fatal-warnings >>"$LOG" 2>&1; then
  fail "flutter analyze"
fi

echo "[VERIFY] flutter test ..."
# Regression-Schutz: alle Widget-/Unit-Tests muessen gruen sein. Bei rot liest
# der Auto-Fix-Schritt die exakten Fehler aus dem Log.
if ! flutter test --reporter expanded >>"$LOG" 2>&1; then
  fail "flutter test (Regression / neue Tests rot)"
fi

echo "[VERIFY] flutter build web ..."
if ! flutter build web --release \
    "--dart-define=SUPABASE_URL=${SUPABASE_URL_FB:-https://adtviduaftdquvfjpojb.supabase.co}" \
    "--dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek-api.brandy13062.workers.dev" \
    "--dart-define=APP_VERSION=godmode-verify" >>"$LOG" 2>&1; then
  fail "flutter build web"
fi

echo "[VERIFY] Alles gruen."
echo "true" > .godmode_verify_ok
exit 0
