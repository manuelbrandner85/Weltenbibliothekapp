# LiveKit-WB — Eigene Instanz für Weltenbibliothek

Eigene LiveKit-Instanz auf dem Hostinger-VPS, **strikt getrennt** von Mensaena's
LiveKit. Diese README dokumentiert die Trennung und alle Mensaena-Schutzmaßnahmen.

## Architektur

```
Hostinger VPS (72.62.154.95)
│
├── Mensaena (UNVERÄNDERT, NICHT BERÜHREN)
│   ├── Web-Server (irgendein Reverse Proxy) → Ports 80/443
│   ├── /docker/livekit/        → Mensaena's livekit.yaml + compose
│   └── Mensaena's livekit-Container → port 7880 intern, UDP 50000–60000, TCP 7881
│
└── Weltenbibliothek (DIESES SETUP)
    ├── /docker/livekit-wb/     → Eigene Konfiguration
    ├── livekit-weltenbibliothek-Container → Port 7980 intern, UDP 60001–65000, TCP 7981
    └── traefik-weltenbibliothek → Ports 7891/7892, eigener Reverse Proxy
        └── Domain: livekit-wb.srv1438024.hstgr.cloud:7892
```

## Trennungs-Garantien (Mensaena-Schutz)

| Aspekt | Mensaena | WB | Konflikt? |
|---|---|---|---|
| Verzeichnis | `/docker/livekit/` | `/docker/livekit-wb/` | ❌ Nein |
| Container-Name | `livekit` (oder ähnlich) | `livekit-weltenbibliothek` | ❌ Nein |
| Web-Ports | 80/443 (TCP) | 7891/7892 (TCP) | ❌ Nein |
| RTC-TCP | 7881 | 7981 | ❌ Nein |
| RTC-UDP-Range | 50000–60000 | 60001–65000 | ❌ Nein |
| TURN UDP | 5350/3479 (vermutl.) | **deaktiviert** | ❌ Nein |
| LiveKit intern | 7880 | 7980 | ❌ Nein |
| API-Key | `mensaena-...` | `wb-...` | ❌ Nein |
| Docker-Network | (Mensaena's eigenes) | `livekit-wb-net` | ❌ Nein |
| TLS-Cert | (eigene Verwaltung) | Read-only-Mount (`:ro`) | ❌ Nein |
| Domain | `livekit.srv1438024…` | `livekit-wb.srv1438024…` | ❌ Nein |

## Was die WB-Workflows NIEMALS dürfen

- ❌ `/docker/livekit/` modifizieren (das ist Mensaena's Verzeichnis)
- ❌ Mensaena's Container restarten/stoppen
- ❌ Mensaena's `livekit.yaml` lesen, schreiben oder überschreiben
- ❌ Ports 80/443 belegen
- ❌ UDP-Range 50000–60000 oder 5350/3479 belegen
- ❌ Mensaena's API-Key in WB-Configs einbauen

## Was die WB-Workflows DÜRFEN

- ✅ Read-only Mount des Hostinger-Wildcard-Certs (`/etc/letsencrypt/live/…/`)
- ✅ Eigenes Verzeichnis `/docker/livekit-wb/` schreiben
- ✅ Eigene Container `livekit-weltenbibliothek` und `traefik-weltenbibliothek` starten/stoppen
- ✅ Eigene Ports 7891/7892/7981/60001-65000 belegen

## Deploy

Per CI: Änderung an `infra/livekit-wb/**` triggert `deploy_livekit_wb.yml`.

Manuell auf VPS:
```bash
cd /docker/livekit-wb
docker compose up -d         # Starten
docker compose ps            # Status
docker compose logs -f       # Logs live
docker compose restart       # Restart (Mensaena nicht betroffen)
docker compose down          # Stoppen (Mensaena nicht betroffen)
```

## Deployment-Health-Checks (im Workflow)

Der `deploy_livekit_wb.yml`-Workflow macht vor und nach jedem Deploy:

1. **Pre-Deploy**: Listet alle LiveKit-Container auf — Mensaena muss laufen
2. **Port-Konflikt-Check**: Sicherstellen dass 7891/7892/7981 frei sind
3. **Cert-Pfad-Lookup**: Hostinger-Wildcard-Cert finden (read-only Mount)
4. **WB-Container starten**
5. **Post-Deploy Mensaena-Check**: Mensaena muss noch healthy sein, sonst FAIL
6. **WB-Health-Check**: Eigener Container reagiert auf https://…:7892

Wenn Mensaena nach unserem Deploy nicht mehr läuft, **failt der Workflow
absichtlich rot** — damit kein versehentlicher Schaden bestehen bleibt.

## URL-Schema

```
WB-LiveKit-URL:  wss://livekit-wb.srv1438024.hstgr.cloud:7892
WB-Token-URL:    https://adtviduaftdquvfjpojb.supabase.co/functions/v1/livekit-token
```

App injectet die URL über `--dart-define=LIVEKIT_URL=…` zur Build-Zeit.
Edge Function generiert das Token mit dem WB-Key (HMAC-SHA256).

## Secret-Inventar

| Secret | Wo | Wofür |
|---|---|---|
| `wb-a9b26485d407e7dc2043` (Key) | livekit.yaml + Edge Function + Worker | LiveKit API Identität |
| `f9c576...` (Secret) | livekit.yaml + Edge Function + Worker | JWT-Signing |
| `LIVEKIT_URL` | Edge Function + Worker + App | Server-Endpunkt |

GitHub-Secrets (überschreiben Defaults):
- `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `LIVEKIT_URL`
- `VPS_PASSWORD` (für SSH-Deploy)

⚠️ Die LiveKit-Keys liegen aktuell auch im Klartext in den Workflow-Dateien als
Fallback. Das ist **historisch gewachsen** und sollte langfristig in echte
GitHub-Secrets umziehen + Keys rotieren. Siehe Audit-Findings.
