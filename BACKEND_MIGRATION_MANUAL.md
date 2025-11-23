# 🎯 BACKEND MIGRATION - Manuelle Anleitung (Cloudflare Dashboard)

## Wenn du lieber über das Cloudflare Dashboard arbeiten möchtest

---

## 📋 Voraussetzungen

- ✅ Cloudflare-Konto mit aktivem Workers & D1 Zugang
- ✅ `weltenbibliothek` D1 Datenbank existiert
- ✅ `weltenbibliothek_worker` ist deployed
- ✅ Zugriff auf Cloudflare Dashboard

---

## 🔧 SCHRITT 1: D1 Datenbank-Migration

### 1.1 Cloudflare Dashboard öffnen
1. Gehe zu: **https://dash.cloudflare.com/**
2. Wähle dein Account
3. Navigiere zu: **Workers & Pages** → **D1 SQL Database**

### 1.2 Datenbank öffnen
1. Klicke auf deine **weltenbibliothek** Datenbank
2. Gehe zum **Console** Tab

### 1.3 Migration ausführen

Führe folgende SQL-Befehle **nacheinander** aus:

#### Befehl 1: Spalte hinzufügen
```sql
ALTER TABLE live_rooms ADD COLUMN chat_room_id TEXT;
```

**Erwartete Ausgabe:** `Query executed successfully`

#### Befehl 2: Index erstellen
```sql
CREATE INDEX IF NOT EXISTS idx_live_rooms_chat_room_status 
ON live_rooms(chat_room_id, status);
```

**Erwartete Ausgabe:** `Query executed successfully`

### 1.4 Migration verifizieren

#### Verifizierung 1: Spalte prüfen
```sql
PRAGMA table_info(live_rooms);
```

**Erwartete Ausgabe:** Liste aller Spalten, `chat_room_id` sollte vorhanden sein

#### Verifizierung 2: Index prüfen
```sql
PRAGMA index_list(live_rooms);
```

**Erwartete Ausgabe:** Liste aller Indizes, `idx_live_rooms_chat_room_status` sollte vorhanden sein

#### Verifizierung 3: Aktuelle Daten anzeigen
```sql
SELECT room_id, chat_room_id, host_username, status 
FROM live_rooms 
WHERE status = 'live';
```

**Erwartete Ausgabe:** 
- Leere Liste (wenn keine aktiven Streams) ✅
- Liste mit Streams, `chat_room_id` wird `NULL` sein (alte Streams) ⚠️

**WICHTIG:** Alte Streams mit `chat_room_id = NULL` sollten **beendet** werden, da sie die neue Validierung umgehen:

```sql
-- Optional: Alte Streams beenden
UPDATE live_rooms 
SET status = 'ended', ended_at = strftime('%s', 'now') 
WHERE status = 'live' AND chat_room_id IS NULL;
```

---

## 🚀 SCHRITT 2: Worker Code deployen

### Option A: Über Wrangler CLI (Empfohlen)

```bash
cd /home/user/flutter_app/cloudflare_backend
npx wrangler deploy weltenbibliothek_worker.js
```

### Option B: Über Cloudflare Dashboard

#### 2.1 Worker öffnen
1. Gehe zu: **Workers & Pages**
2. Klicke auf deinen **weltenbibliothek** Worker

#### 2.2 Code aktualisieren
1. Klicke auf **Quick Edit** oder **Edit Code**
2. Kopiere den **kompletten Inhalt** von `/home/user/flutter_app/cloudflare_backend/weltenbibliothek_worker.js`
3. Füge ihn in den Editor ein
4. Klicke auf **Save and Deploy**

#### 2.3 Deployment verifizieren
1. Gehe zum **Logs** Tab
2. Klicke auf **Begin log stream**
3. Teste einen API-Call (z.B. GET /api/live/rooms)
4. Prüfe, ob Logs erscheinen

---

## 🧪 SCHRITT 3: Testing

### 3.1 Test-Szenario 1: Normaler Stream-Create

**Request:**
```bash
curl -X POST https://DEIN-WORKER.workers.dev/api/live/rooms \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer DEIN-JWT-TOKEN" \
  -d '{
    "chatRoomId": "allgemeiner_chat",
    "title": "Test Stream",
    "description": "Migration Test",
    "category": "test"
  }'
```

**Erwartete Response:**
```json
{
  "success": true,
  "room": {
    "room_id": "room_123_1234567890",
    "chat_room_id": "allgemeiner_chat",
    "title": "Test Stream",
    "host_username": "dein_username",
    "status": "live"
  }
}
```

### 3.2 Test-Szenario 2: Chat Room Occupied

**Vorbedingung:** Stream aus Szenario 1 ist noch aktiv

**Request:** (gleicher Request wie oben, anderer User)

**Erwartete Response:**
```json
{
  "error": "Dieser Chat-Raum hat bereits einen aktiven Livestream",
  "error_type": "chat_room_occupied",
  "existing_stream": {
    "room_id": "room_123_1234567890",
    "host_username": "erster_user",
    "host_user_id": 123
  }
}
```

**HTTP Status:** `409 Conflict`

### 3.3 Test-Szenario 3: User Has Stream

**Vorbedingung:** User hat bereits Stream in anderem Chat

**Erwartete Response:**
```json
{
  "error": "Du hast bereits einen aktiven Livestream in einem anderen Chat",
  "error_type": "user_has_stream",
  "existing_room": {
    "room_id": "room_123_1234567890",
    "chat_room_id": "musik_chat"
  }
}
```

**HTTP Status:** `409 Conflict`

---

## 🔍 SCHRITT 4: Monitoring & Debugging

### 4.1 Cloudflare Logs prüfen

1. Gehe zu **Workers & Pages** → **Dein Worker** → **Logs**
2. Filter auf `409` Errors
3. Prüfe `error_type` in Responses

### 4.2 Datenbank-Zustand prüfen

```sql
-- Alle aktiven Streams
SELECT room_id, chat_room_id, host_username, status, created_at
FROM live_rooms 
WHERE status = 'live'
ORDER BY created_at DESC;

-- Streams pro Chat-Raum
SELECT chat_room_id, COUNT(*) as stream_count
FROM live_rooms
WHERE status = 'live'
GROUP BY chat_room_id;
```

**Erwartete Ausgabe:** Pro `chat_room_id` maximal 1 Stream mit `status='live'` ✅

### 4.3 Index-Performance prüfen

```sql
EXPLAIN QUERY PLAN
SELECT * FROM live_rooms 
WHERE chat_room_id = 'allgemeiner_chat' AND status = 'live';
```

**Erwartete Ausgabe:** Sollte `USING INDEX idx_live_rooms_chat_room_status` enthalten ✅

---

## 🚨 Troubleshooting

### Problem 1: Migration schlägt fehl
**Fehler:** `duplicate column name: chat_room_id`

**Ursache:** Migration wurde bereits ausgeführt

**Lösung:** 
```sql
-- Prüfen ob Spalte existiert
PRAGMA table_info(live_rooms);
-- Wenn vorhanden, Migration überspringen
```

### Problem 2: Worker-Deployment schlägt fehl
**Fehler:** `Authentication error`

**Lösung:**
```bash
# Neu einloggen
npx wrangler login

# Dann erneut deployen
npx wrangler deploy weltenbibliothek_worker.js
```

### Problem 3: 400 Error "Chat Room ID is required"
**Ursache:** Flutter-App sendet `chatRoomId` nicht

**Lösung:** 
- Flutter-App muss auf v3.3.0 geupdatet sein
- Prüfe Request-Body in Network-Tab (Browser DevTools)

### Problem 4: Alte Streams mit NULL chat_room_id
**Ursache:** Streams vor Migration haben kein `chat_room_id`

**Lösung:**
```sql
-- Alle alten Streams beenden
UPDATE live_rooms 
SET status = 'ended', ended_at = strftime('%s', 'now')
WHERE status = 'live' AND chat_room_id IS NULL;
```

---

## ✅ Post-Migration Checklist

Nach erfolgreicher Migration:

- [ ] D1-Schema hat `chat_room_id` Spalte
- [ ] Index `idx_live_rooms_chat_room_status` existiert
- [ ] Worker deployed (v3.3.0)
- [ ] Test 1: Stream erstellen → SUCCESS (201)
- [ ] Test 2: Zweiter Stream im gleichen Chat → 409 Error
- [ ] Test 3: Error-Response hat `error_type` Feld
- [ ] Flutter-App zeigt "Beitreten"-Button bei 409
- [ ] Cloudflare Logs zeigen korrekte Requests
- [ ] Keine alten Streams mit NULL chat_room_id

---

## 📚 Weitere Ressourcen

- **Vollständige Anleitung:** `BACKEND_MIGRATION_GUIDE.md`
- **Änderungsprotokoll:** `CHANGELOG_v3.3.0.md`
- **Schnell-Referenz:** `QUICK_REFERENCE_v3.3.0.md`
- **Architektur-Diagramm:** `ARCHITECTURE_FLOW_v3.3.0.txt`

---

## 🔄 Rollback (Falls nötig)

### Datenbank rollback (Optional)
```sql
-- WARNUNG: SQLite unterstützt ALTER TABLE DROP COLUMN nicht!
-- Spalte kann nicht entfernt werden, aber unbedenklich lassen
```

### Worker rollback
```bash
# Alte Version aus Git auschecken
cd /home/user/flutter_app/cloudflare_backend
git checkout HEAD~1 weltenbibliothek_worker.js

# Alte Version deployen
npx wrangler deploy weltenbibliothek_worker.js
```

### Flutter-App rollback
```bash
cd /home/user/flutter_app
git checkout v3.2.0
flutter clean && flutter pub get
flutter build apk --release
```

---

**Version:** 3.3.0+44  
**Migrations-Datum:** 2025-01-XX  
**Geschätzte Dauer:** 10-15 Minuten  
**Kritikalität:** 🔴 HIGH (Breaking Changes)
