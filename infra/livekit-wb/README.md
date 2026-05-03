# LiveKit-WB — Eigene Instanz für Weltenbibliothek

Eigene LiveKit-Instanz auf dem Hostinger-VPS, **strikt getrennt** von Mensaena's
LiveKit. Diese README dokumentiert die Trennung und alle Mensaena-Schutzmaßnahmen.

## Architektur

```
Hostinger VPS (72.62.154.95)
│
├── Mensaena's Caddy (livekit-caddy-1) — Reverse-Proxy auf Ports 80/443
│   ├── Site `livekit.srv1438024.hstgr.cloud` → Mensaena's LiveKit
│   └── Site `livekit-wb.srv1438024.hstgr.cloud` → WB-LiveKit (NEU, additiv)
│       └── proxied auf 127.0.0.1:7980 (WB-Container intern)
│
├── Mensaena's LiveKit (livekit-livekit-1) — Port 7880 intern, UDP 50000–60000
│
└── Weltenbibliothek (DIESES SETUP)
    ├── /docker/livekit-wb/ — eigenes Verzeichnis (kein Overlap mit Mensaena)
    ├── livekit-weltenbibliothek-Container — Port 7980 intern, UDP 60001–65000, TCP 7981
    └── KEIN eigener Reverse-Proxy — Caddy von Mensaena macht's via Snippet
```

## Trennungs-Garantien (Mensaena-Schutz)

| Aspekt | Mensaena | WB | Konflikt? |
|---|---|---|---|
| Verzeichnis | (eigenes) | `/docker/livekit-wb/` | ❌ Nein |
| Container-Name | `livekit-livekit-1`, `livekit-caddy-1` | `livekit-weltenbibliothek` | ❌ Nein |
| Web-Ports | 80/443 (TCP, via Caddy) | nur intern 127.0.0.1:7980 | ❌ Nein |
| RTC-TCP | 7881 | 7981 | ❌ Nein |
| RTC-UDP-Range | 50000–60000 | 60001–65000 | ❌ Nein |
| TURN UDP | 5350/3479 (vermutl.) | **deaktiviert** | ❌ Nein |
| LiveKit intern | 7880 | 7980 | ❌ Nein |
| API-Key | `mensaena-…` | `wb-…` | ❌ Nein |
| Docker-Network | (eigenes) | `livekit-wb-net` | ❌ Nein |
| TLS-Cert | Caddy ACME (eigener) | Caddy ACME (eigener für `livekit-wb.*`) | ❌ Nein |
| Domain | `livekit.srv1438024…` | `livekit-wb.srv1438024…` | ❌ Nein |

## Caddy-Snippet — Mensaena-additiv

`caddy-snippet.caddy` enthält die Site-Definition für `livekit-wb.*`. Der Workflow
`deploy_livekit_wb.yml` fügt sie zwischen den Markern `# >>> WB-LIVEKIT-BEGIN` und
`# <<< WB-LIVEKIT-END` in Mensaena's Caddyfile ein.

**Sicherheit:**
- ✅ **Backup vor jedem Edit** (`/docker/livekit-wb/caddyfile-backups/Caddyfile.<ts>.bak`)
- ✅ **Idempotent** — bei Re-Deploy wird der Block ersetzt, nicht angehängt
- ✅ **Caddy-Validate vor Reload** — Syntax-Fehler = kein Reload, Backup wird wiederhergestellt
- ✅ **Caddy-Reload statt Restart** — Mensaena hat 0s Downtime
- ✅ **Auto-Rollback** bei Reload-Fehler — alter Caddyfile-State wird wiederhergestellt

## Was die WB-Workflows NIEMALS dürfen

- ❌ Mensaena's Container restarten/stoppen
- ❌ Mensaena's `livekit.yaml` lesen, schreiben oder überschreiben
- ❌ Mensaena's Site-Definitionen in der Caddyfile ändern
- ❌ Eigene Ports 80/443 belegen (würde Caddy blockieren)
- ❌ UDP-Range 50000–60000 oder 5350/3479 belegen
- ❌ Mensaena's API-Key in WB-Configs einbauen

## Was die WB-Workflows DÜRFEN

- ✅ Eigenes Verzeichnis `/docker/livekit-wb/` schreiben
- ✅ Eigenen Container `livekit-weltenbibliothek` starten/stoppen
- ✅ Eigene Ports 7980 (lokal), 7981 (TCP), 60001-65000 (UDP) belegen
- ✅ Mensaena's Caddyfile **additiv** zwischen WB-BEGIN/END-Markern erweitern
- ✅ `caddy reload` (graceful) auslösen

## Deploy

Per CI: Änderung an `infra/livekit-wb/**` triggert `deploy_livekit_wb.yml`.

Manuell auf VPS:
```bash
cd /docker/livekit-wb
docker compose up -d           # WB-Container starten
docker compose ps              # Status
docker compose logs -f         # Logs live
docker compose down            # Stoppen (Mensaena nicht betroffen)
```

Caddy-Reload (manuell):
```bash
docker exec livekit-caddy-1 caddy reload --config /etc/caddy/Caddyfile
```

## Deployment-Schritte (im Workflow)

`deploy_livekit_wb.yml`:

1. **Pre-Deploy**: Mensaena's Caddy + LiveKit müssen laufen
2. **Port-Konflikt-Check**: 7980/7981/60001 frei
3. **Caddyfile-Pfad ermitteln** via `docker inspect`
4. **WB-Container starten** (intern auf 127.0.0.1:7980)
5. **Caddyfile additiv erweitern** mit Backup + Validate + Reload + Rollback
6. **Post-Deploy Mensaena-Check** — beide Container weiter Up + extern erreichbar
7. **WB-Health-Check** — `https://livekit-wb.srv1438024.hstgr.cloud`

Wenn Mensaena nach dem Deploy nicht mehr healthy ist, **failt der Workflow rot**.

## URL-Schema

```
WB-LiveKit-URL:  wss://livekit-wb.srv1438024.hstgr.cloud   (Standard-Port 443)
WB-Token-URL:    https://adtviduaftdquvfjpojb.supabase.co/functions/v1/livekit-token
```

App injectet die URL über `--dart-define=LIVEKIT_URL=…` zur Build-Zeit.
Edge Function generiert das Token mit dem WB-Key (HMAC-SHA256).

## Secret-Inventar

| Secret | Wo | Wofür |
|---|---|---|
| `wb-a9b26485d407e7dc2043` (Key) | livekit.yaml + Edge Function + Worker | LiveKit API Identität |
| `f9c576…` (Secret) | livekit.yaml + Edge Function + Worker | JWT-Signing |
| `LIVEKIT_URL` | Edge Function + Worker + App | Server-Endpunkt |

GitHub-Secrets (überschreiben Defaults):
- `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_URL`
- `VPS_PASSWORD` (für SSH-Deploy)

⚠️ Die LiveKit-Keys liegen aktuell auch im Klartext in den Workflow-Dateien als
Fallback. Das ist **historisch gewachsen** und sollte langfristig in echte
GitHub-Secrets umziehen + Keys rotieren. Siehe Audit-Findings.
<!-- re-deploy-trigger: 2026-05-02-2 (nach Hostinger-Whitelist) -->
<!-- selfhost-trigger: 20260502-204804 -->
<!-- selfhost-trigger: 20260502-215606 -->
<!-- selfhost-trigger: 20260502-220206 -->
<!-- selfhost-trigger: 20260502-233019 -->
