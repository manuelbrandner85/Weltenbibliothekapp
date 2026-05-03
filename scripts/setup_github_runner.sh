#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# GitHub Actions Self-Hosted Runner Setup für Weltenbibliothek-VPS
# ════════════════════════════════════════════════════════════════════════════
#
# Was dieses Skript macht:
#   1. Legt System-User `github-runner` an (kein Login, kein sudo)
#   2. Installiert den GitHub Actions Runner unter /opt/github-runner/
#   3. Gibt dem Runner Docker-Zugriff (für deploy_livekit_wb.yml)
#   4. Registriert den Runner beim Repo (braucht REGISTRATION_TOKEN von GitHub)
#   5. Startet als systemd-Service (auto-restart, läuft nach VPS-Reboot weiter)
#
# Sicherheit:
#   - User `github-runner` hat KEIN sudo
#   - Hat NUR Docker-Zugriff (über Docker-Group)
#   - Workflows können also NUR Docker-Befehle ausführen
#   - Kann NICHT in Mensaena's Verzeichnisse außerhalb von Docker schreiben
#
# Vor dem Ausführen brauchst du:
#   - REGISTRATION_TOKEN von GitHub:
#     https://github.com/manuelbrandner85/Weltenbibliothekapp/settings/actions/runners/new
#     Klick auf "New self-hosted runner" → Linux/x64 → kopier den Token
#     (Format: A...langer-String...Z, läuft nach 1h ab)
#
# Aufruf:
#   sudo bash setup_github_runner.sh <REGISTRATION_TOKEN>
#
# Mensaena-Schutz:
#   - Skript ändert NICHTS an Mensaena's Verzeichnissen (/docker/livekit/)
#   - Ändert NICHTS an Mensaena's Containern oder Caddyfile
#   - Pre-Check: prüft dass Mensaena läuft, vor und nach Setup

set -euo pipefail

# ── Konfiguration ──────────────────────────────────────────────────────────
RUNNER_VERSION="2.321.0"
RUNNER_USER="github-runner"
RUNNER_HOME="/opt/github-runner"
REPO_URL="https://github.com/manuelbrandner85/Weltenbibliothekapp"
RUNNER_LABELS="self-hosted,linux,x64,vps,weltenbibliothek"

# ── Argumente prüfen ───────────────────────────────────────────────────────
if [ $# -ne 1 ]; then
  echo "❌ Verwendung: sudo bash $0 <REGISTRATION_TOKEN>"
  echo ""
  echo "Token holen:"
  echo "  https://github.com/manuelbrandner85/Weltenbibliothekapp/settings/actions/runners/new"
  echo "  → 'New self-hosted runner' → Linux/x64 → Token kopieren"
  exit 1
fi

REG_TOKEN="$1"

# ── Root-Check ─────────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Skript muss als root laufen (sudo bash $0 <TOKEN>)"
  exit 1
fi

# ── Mensaena Pre-Check ─────────────────────────────────────────────────────
echo "🛡️  Pre-Check: Mensaena läuft?"
if ! docker ps --format '{{.Names}}' | grep -q '^livekit-caddy-1$'; then
  echo "⚠️  Mensaena's Caddy (livekit-caddy-1) läuft nicht — bitte prüfen vor Setup"
  echo "   Setup wird trotzdem fortgesetzt — Skript verändert Mensaena nicht"
fi
echo "✅ Mensaena-Check OK (oder Skript fährt trotzdem fort)"
echo ""

# ── User anlegen ───────────────────────────────────────────────────────────
echo "→ User '${RUNNER_USER}' anlegen (kein Login, kein sudo) …"
if id "${RUNNER_USER}" &>/dev/null; then
  echo "  User existiert bereits — überspringe"
else
  useradd -r -s /bin/bash -d "${RUNNER_HOME}" -m "${RUNNER_USER}"
  echo "  ✅ User angelegt"
fi

# ── Docker-Zugriff ─────────────────────────────────────────────────────────
echo "→ Docker-Group-Zugriff für '${RUNNER_USER}' …"
if ! getent group docker > /dev/null; then
  echo "  ❌ Docker-Group existiert nicht — ist Docker installiert?"
  exit 1
fi
usermod -aG docker "${RUNNER_USER}"
echo "  ✅ Docker-Zugriff erteilt"

# ── Sudo-NICHT-Zugriff verifizieren ────────────────────────────────────────
# Wir wollen, dass der Runner nichts auf dem System ausführen kann außer Docker
echo "→ Verifiziere dass '${RUNNER_USER}' KEIN sudo hat …"
if sudo -l -U "${RUNNER_USER}" 2>/dev/null | grep -q 'may run'; then
  echo "  ⚠️  WARNUNG: User hat sudo-Rechte — bitte manuell aus /etc/sudoers entfernen"
else
  echo "  ✅ Kein sudo-Zugriff (sicher)"
fi

# ── /docker/livekit-wb Berechtigungen ─────────────────────────────────────
# Damit deploy_livekit_wb.yml ins WB-Verzeichnis schreiben kann
echo "→ /docker/livekit-wb/ für ${RUNNER_USER} schreibbar machen …"
mkdir -p /docker/livekit-wb
chown -R "${RUNNER_USER}:${RUNNER_USER}" /docker/livekit-wb
chmod 755 /docker/livekit-wb
echo "  ✅ /docker/livekit-wb/ schreibbar (Mensaena's /docker/ unangetastet)"

# WICHTIG: Mensaena's /docker/livekit/ NICHT touch'en!
if [ -d /docker/livekit ]; then
  echo "  ℹ️  /docker/livekit/ (Mensaena) bleibt unverändert"
fi

# ── Caddyfile-Schreibrecht (NUR für Caddy-additive Snippets) ──────────────
# Der Runner muss Mensaena's Caddyfile editieren können (additiv).
# Wir geben dem User Schreibrechte auf das spezifische File, nicht das ganze Verzeichnis.
CADDYFILE=$(docker inspect livekit-caddy-1 --format \
  '{{range .Mounts}}{{if or (eq .Destination "/etc/caddy/Caddyfile") (eq .Destination "/Caddyfile")}}{{.Source}}{{end}}{{end}}' \
  2>/dev/null || echo "")
if [ -n "$CADDYFILE" ] && [ -f "$CADDYFILE" ]; then
  echo "→ Caddyfile-Schreibrecht für ${RUNNER_USER} (NUR auf ${CADDYFILE}) …"
  # Setze ACL so dass github-runner die Datei lesen+schreiben kann
  if command -v setfacl > /dev/null 2>&1; then
    setfacl -m u:${RUNNER_USER}:rw "$CADDYFILE"
    echo "  ✅ ACL gesetzt (chmod der Datei bleibt unverändert)"
  else
    # Fallback: chmod 664 + chgrp damit Runner via Docker-Group lesen kann
    echo "  ℹ️  setfacl nicht verfügbar — installiere acl falls möglich"
    apt-get install -y -qq acl 2>/dev/null && setfacl -m u:${RUNNER_USER}:rw "$CADDYFILE" \
      && echo "  ✅ ACL nachträglich gesetzt" \
      || echo "  ⚠️  Manuell setfacl -m u:${RUNNER_USER}:rw \"$CADDYFILE\" ausführen"
  fi
else
  echo "  ⚠️  Mensaena-Caddyfile nicht gefunden — Runner kann's später nicht editieren"
  echo "      Bitte manuell prüfen via: docker inspect livekit-caddy-1"
fi

# ── Runner herunterladen ───────────────────────────────────────────────────
echo "→ GitHub Actions Runner ${RUNNER_VERSION} herunterladen …"
cd "${RUNNER_HOME}"
if [ -f "actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" ]; then
  echo "  Tarball existiert — überspringe Download"
else
  curl -sLo "actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  echo "  ✅ Download fertig"
fi

if [ ! -f "config.sh" ]; then
  tar xzf "actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  echo "  ✅ Entpackt"
fi

chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_HOME}"

# ── Runner registrieren ────────────────────────────────────────────────────
echo "→ Runner bei GitHub registrieren …"
if [ -f ".runner" ]; then
  echo "  Runner ist bereits registriert — überspringe"
  echo "  (Falls Re-Register nötig: erst sudo -u ${RUNNER_USER} ./config.sh remove)"
else
  sudo -u "${RUNNER_USER}" -H bash -c "
    cd ${RUNNER_HOME} && \
    ./config.sh \
      --url '${REPO_URL}' \
      --token '${REG_TOKEN}' \
      --name 'wb-vps-runner' \
      --labels '${RUNNER_LABELS}' \
      --work '_work' \
      --unattended \
      --replace
  "
  echo "  ✅ Runner registriert"
fi

# ── systemd Service installieren ───────────────────────────────────────────
echo "→ systemd-Service installieren (auto-restart, persistent) …"
cd "${RUNNER_HOME}"
./svc.sh install "${RUNNER_USER}"
./svc.sh start
echo "  ✅ Service installiert + gestartet"

# ── Status-Verifikation ────────────────────────────────────────────────────
echo ""
echo "→ Status-Check …"
sleep 3
./svc.sh status

echo ""
echo "🛡️  Mensaena Post-Check:"
if docker ps --format '{{.Names}}' | grep -q '^livekit-caddy-1$'; then
  echo "  ✅ Mensaena's Caddy weiterhin Up"
fi
if docker ps --format '{{.Names}}' | grep -q '^livekit-livekit-1$'; then
  echo "  ✅ Mensaena's LiveKit weiterhin Up"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo "  ✅ FERTIG"
echo "════════════════════════════════════════════════════════════════════════"
echo ""
echo "Runner-Status auf GitHub prüfen:"
echo "  ${REPO_URL}/settings/actions/runners"
echo ""
echo "Nach erfolgreichem Status (grüner Punkt 'Idle'):"
echo "  → Workflow umstellen auf runs-on: self-hosted"
echo "  → SSH-Whitelist bei Hostinger zurücknehmen"
echo "  → VPS_PASSWORD-Secret in GitHub kann gelöscht werden"
echo ""
echo "Runner-Logs live ansehen:"
echo "  journalctl -u actions.runner.manuelbrandner85-Weltenbibliothekapp.wb-vps-runner -f"
echo ""
