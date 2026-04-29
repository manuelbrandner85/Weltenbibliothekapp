# 🎥 LiveKit Server-Setup für Weltenbibliothek

> **Status (2026-04-27):** App-Code für LiveKit ist deployed. Damit Video-Calls
> tatsächlich funktionieren, musst du einmalig den eigenen LiveKit-Container auf
> dem Hostinger-VPS hochziehen. Anleitung in 12 Phasen — jede Phase ist
> abgeschlossen testbar bevor du weitergehst.

---

## Wichtige Sicherheitsregeln

- ⚠️ **VPS-Passwort sofort ändern** beim ersten SSH-Login (`passwd`)
- ⚠️ **KEIN bestehender Mensaena-Container wird angefasst** — alle Befehle
  erstellen NEUE Container/Configs/Volumes mit Suffix `-wb`
- ⚠️ **API-Keys NICHT in Git** committen — `credentials.txt` bleibt nur auf
  dem VPS

---

## Phase 1 — VPS verbinden + bestehende Konfiguration LESEN

```bash
ssh root@<DEINE-HOSTINGER-VPS-IP>

# Passwort sofort ändern
passwd

# Bestehende Container anzeigen (NUR ANSCHAUEN, NICHTS ÄNDERN)
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"

# Bestehende LiveKit-Config FINDEN (Mensaena)
find / -name "livekit.yaml" -type f 2>/dev/null

# Werte aus der bestehenden livekit.yaml NOTIEREN:
cat <PFAD>/livekit.yaml
# → port, rtc.port_range_start/end, rtc.tcp_port,
#   turn.tls_port, turn.udp_port, turn.domain
# Diese Werte sind BELEGT — der neue Container braucht andere.

# Belegte Ports prüfen
ss -tulnp | grep -E 'LISTEN|udp' | sort -t: -k2 -n
```

**Test Phase 1:** Du kennst jetzt die Mensaena-Ports und weißt welche Ports
für den WB-Container frei sind.

---

## Phase 2 — Port-Mapping

Wenn Mensaena diese Ports nutzt, nimm für WB die rechte Spalte:

| Funktion         | Mensaena (belegt) | Weltenbibliothek (NEU) |
|------------------|-------------------|------------------------|
| HTTP API         | 7880              | 7890                   |
| WebRTC TCP       | 7881              | 7891                   |
| TURN TLS         | 5349              | 5350                   |
| TURN UDP         | 3478              | 3479                   |
| WebRTC UDP Range | 50000-60000       | 60001-65000            |
| HTTPS (Caddy)    | 443               | 4443                   |

```bash
# Prüfe dass die WB-Ports frei sind:
ss -tulnp | grep -E '7890|7891|5350|3479|4443'
# Muss LEER sein
```

**Test Phase 2:** Alle WB-Ports sind frei.

---

## Phase 3 — DNS einrichten

Beim Domain-Provider zwei A-Records anlegen (bestehende Mensaena-Records
NICHT ändern):

```
livekit-wb.deine-domain.de         A    <VPS-IP>
livekit-wb-turn.deine-domain.de    A    <VPS-IP>
```

5–30 Minuten Propagation abwarten.

```bash
# Test:
host livekit-wb.deine-domain.de
# → muss VPS-IP zurückgeben
```

**Test Phase 3:** DNS auflöst korrekt auf VPS-IP.

---

## Phase 4 — Verzeichnis + eigene API-Keys

```bash
mkdir -p /opt/livekit-wb
cd /opt/livekit-wb

# Eigene Keys (NICHT die von Mensaena!)
export LK_WB_KEY="APIkey_wb_$(openssl rand -hex 8)"
export LK_WB_SECRET="$(openssl rand -base64 36 | tr -d '=/+' | head -c 48)"

cat > /opt/livekit-wb/credentials.txt << EOF
═══ WELTENBIBLIOTHEK LIVEKIT CREDENTIALS ═══
Domain:     livekit-wb.deine-domain.de
WSS URL:    wss://livekit-wb.deine-domain.de
API Key:    $LK_WB_KEY
API Secret: $LK_WB_SECRET
Erstellt:   $(date)
═════════════════════════════════════════════
EOF
chmod 600 /opt/livekit-wb/credentials.txt

cat /opt/livekit-wb/credentials.txt
```

**Test Phase 4:** `credentials.txt` existiert mit eigenen Keys.

---

## Phase 5 — `livekit.yaml` (Server-Config)

```bash
cat > /opt/livekit-wb/livekit.yaml << EOF
port: 7890
rtc:
  port_range_start: 60001
  port_range_end: 65000
  tcp_port: 7891
  use_external_ip: true
turn:
  enabled: true
  domain: livekit-wb-turn.deine-domain.de
  tls_port: 5350
  udp_port: 3479
keys:
  ${LK_WB_KEY}: ${LK_WB_SECRET}
room:
  auto_create: true
  max_participants: 50
  empty_timeout: 300
logging:
  level: info
EOF
```

**Test Phase 5:** `cat /opt/livekit-wb/livekit.yaml` zeigt deine Keys eingebettet.

---

## Phase 6 — `caddy.yaml` (TLS-Termination)

```yaml
# /opt/livekit-wb/caddy.yaml
logging:
  logs:
    default:
      level: INFO
storage:
  module: file_system
  root: /data/caddy
apps:
  tls:
    certificates:
      automate:
        - livekit-wb.deine-domain.de
        - livekit-wb-turn.deine-domain.de
  layer4:
    servers:
      main:
        listen: ["0.0.0.0:4443"]
        routes:
          - match:
              - tls:
                  sni:
                    - "livekit-wb-turn.deine-domain.de"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: ["localhost:5350"]
          - match:
              - tls:
                  sni:
                    - "livekit-wb.deine-domain.de"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: ["localhost:7890"]
```

**Test Phase 6:** Datei existiert, beide SNI-Hosts sind eingetragen.

---

## Phase 7 — `docker-compose.yaml`

```yaml
# /opt/livekit-wb/docker-compose.yaml
version: '3.9'
services:
  livekit-wb:
    image: livekit/livekit-server:latest
    container_name: livekit-weltenbibliothek
    network_mode: host
    volumes:
      - ./livekit.yaml:/etc/livekit.yaml:ro
    command: ["--config", "/etc/livekit.yaml"]
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  caddy-wb:
    image: livekit/caddyl4
    container_name: caddy-weltenbibliothek
    network_mode: host
    volumes:
      - ./caddy.yaml:/etc/caddy.yaml:ro
      - caddy-wb-data:/data
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  caddy-wb-data:
    name: caddy-wb-data
```

**Test Phase 7:** Container-Namen + Volume-Namen enden mit `-wb` /
`weltenbibliothek` (kollidiert nicht mit Mensaena).

---

## Phase 8 — Firewall (nur neue Ports öffnen)

```bash
# Wenn ufw aktiv:
ufw allow 4443/tcp comment "LiveKit-WB HTTPS"
ufw allow 7891/tcp comment "LiveKit-WB WebRTC-TCP"
ufw allow 3479/udp comment "LiveKit-WB TURN-UDP"
ufw allow 5350/tcp comment "LiveKit-WB TURN-TLS"
ufw allow 60001:65000/udp comment "LiveKit-WB WebRTC-Media"
ufw reload

# Bestehende Mensaena-Regeln müssen ALLE noch da sein:
ufw status numbered
```

**Test Phase 8:** Mensaena-Firewall-Regeln unverändert, neue WB-Regeln dabei.

---

## Phase 9 — Container starten

```bash
cd /opt/livekit-wb
docker compose up -d

# Nur die NEUEN Container:
docker ps --format "table {{.Names}}\t{{.Status}}" | grep weltenbibliothek

# Mensaena-Container UNVERÄNDERT:
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v weltenbibliothek

# Logs:
docker logs livekit-weltenbibliothek --tail 30
# → "server started" oder "ready"
docker logs caddy-weltenbibliothek --tail 30
# → "certificate obtained" (SSL fertig)
```

**Test Phase 9:** Beide WB-Container laufen, beide Mensaena-Container
laufen weiterhin.

---

## Phase 10 — End-to-End-Test

```bash
# WB erreichbar?
curl -s -o /dev/null -w "%{http_code}" https://livekit-wb.deine-domain.de
# Erwartet: 404 (= Server läuft, SSL OK, kein HTTP-Handler)

# Mensaena IMMER NOCH erreichbar?
curl -s -o /dev/null -w "%{http_code}" https://meet.mensaena.de
# Muss weiterhin funktionieren

# Alle Container?
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
# Mind. 4: 2 Mensaena + 2 Weltenbibliothek
```

**Test Phase 10:** WB-LiveKit liefert 404, Mensaena unverändert.

---

## Phase 11 — Auto-Start bei Reboot

```bash
cat > /etc/systemd/system/livekit-wb.service << 'EOF'
[Unit]
Description=LiveKit Weltenbibliothek Docker
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/opt/livekit-wb
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable livekit-wb.service

# Mensaena-Service unverändert?
systemctl list-units --type=service | grep livekit
# Beide Services müssen sichtbar sein
```

**Test Phase 11:** `livekit-wb.service` ist enabled, Mensaena-Service
unverändert.

---

## Phase 12 — GitHub-Secrets + Worker-Deploy

Auf deinem Entwicklungsrechner (NICHT VPS):

```bash
# GitHub Secrets setzen unter:
# Settings → Secrets and variables → Actions → New repository secret
#   LIVEKIT_API_KEY    = (aus credentials.txt)
#   LIVEKIT_API_SECRET = (aus credentials.txt)
#   LIVEKIT_URL        = wss://livekit-wb.deine-domain.de
```

`deploy_worker.yml` läuft beim nächsten Push auf `main` automatisch und
setzt die Worker-Secrets via Wrangler.

**Test Phase 12:** Im Worker-Dashboard sind die 3 LiveKit-Secrets gesetzt.

---

## Phase 13 — APK-Build mit `LIVEKIT_URL`

`build_apk.yml` muss erweitert werden — `--dart-define=LIVEKIT_URL=...`
beim Build-Schritt mitgeben:

```yaml
# .github/workflows/build_apk.yml (Beispiel-Erweiterung)
- name: Build Release APK
  env:
    LIVEKIT_URL: ${{ secrets.LIVEKIT_URL }}
  run: |
    flutter build apk --release \
      --dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek-api.brandy13062.workers.dev \
      --dart-define=SUPABASE_URL=https://adtviduaftdquvfjpojb.supabase.co \
      --dart-define=SUPABASE_ANON_KEY=eyJ... \
      --dart-define=LIVEKIT_URL=$LIVEKIT_URL
```

**Test Phase 13:** Neuer APK-Release v5.39.0+ enthält `LIVEKIT_URL`.

---

## Was wurde angefasst?

**Neu erstellt:**
- `/opt/livekit-wb/` — Verzeichnis
- `/opt/livekit-wb/{livekit,caddy,docker-compose}.yaml`
- `/opt/livekit-wb/credentials.txt`
- `/etc/systemd/system/livekit-wb.service`
- 5 neue Firewall-Regeln
- 2 neue Container, 1 neues Volume

**NICHT angefasst:**
- Mensaena-Konfiguration in `/opt/livekit/`
- Mensaena-Container, -Volumes, -Caddy
- Bestehende Firewall-Regeln
- Bestehende Systemd-Services

---

## Troubleshooting

**`certificate obtained` kommt nicht in Caddy-Logs:**
- DNS-Propagation noch nicht durch — 5 Min warten, dann
  `docker logs caddy-weltenbibliothek --tail 50`

**Port-Konflikt beim Start:**
- Doppelt-Check `ss -tulnp | grep <port>` — vermutlich nutzt Mensaena
  bereits einen der Ports. WB-Ports in `livekit.yaml` anpassen.

**Worker-Endpoint liefert 503:**
- GitHub-Secrets nicht gesetzt → `deploy_worker.yml` Logs prüfen.
