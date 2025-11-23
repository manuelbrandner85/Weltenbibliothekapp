# 🚀 WELTENBIBLIOTHEK - KOMPLETTES BACKEND SETUP

## 📦 WAS WIRD ERSTELLT:

1. ✅ D1 Datenbank (weltenbibliothek-db)
2. ✅ Worker (weltenbibliothek-backend)
3. ✅ Durable Objects (für WebRTC Signaling)
4. ✅ JWT Secret (für Authentication)
5. ✅ Alle Tabellen und Indizes

---

## 🎯 VORAUSSETZUNGEN:

- ✅ Node.js installiert (für wrangler)
- ✅ Cloudflare Account
- ✅ Terminal/PowerShell Zugriff

---

## 📋 SCHRITT 1: WRANGLER INSTALLIEREN & LOGIN

### Windows PowerShell / Terminal:

```bash
# Wrangler installieren (falls nicht vorhanden)
npm install -g wrangler

# Bei Cloudflare einloggen
wrangler login
```

Ein Browser öffnet sich → Login mit deinem Cloudflare Account

---

## 📋 SCHRITT 2: D1 DATENBANK ERSTELLEN

```bash
# Erstelle neue D1 Datenbank
wrangler d1 create weltenbibliothek-db
```

**WICHTIG:** Kopiere die `database_id` aus der Ausgabe!

Beispiel-Ausgabe:
```
✅ Successfully created DB 'weltenbibliothek-db'
[[d1_databases]]
binding = "DB"
database_name = "weltenbibliothek-db"
database_id = "XXXX-XXXX-XXXX-XXXX"  ← DIESE ID KOPIEREN!
```

---

## 📋 SCHRITT 3: PROJEKT-DATEIEN VORBEREITEN

Ich gebe dir jetzt 4 Dateien die du brauchst:
1. `wrangler.toml` (Konfiguration)
2. `weltenbibliothek_worker.js` (Worker Code)
3. `d1_schema_v3.3.0.sql` (Datenbank Schema)
4. `package.json` (Dependencies)

Erstelle einen Ordner auf deinem Computer:
```
C:\Users\manue\weltenbibliothek-backend\
```

---

## 📋 SCHRITT 4: DATEIEN HERUNTERLADEN

Du brauchst diese Dateien aus der Sandbox:
- `/home/user/flutter_app/cloudflare_backend/weltenbibliothek_worker.js`
- `/home/user/flutter_app/cloudflare_backend/d1_schema_v3.3.0_complete.sql`
- `/home/user/flutter_app/cloudflare_backend/wrangler.toml`

**Ich kann sie dir als Download bereitstellen!**

---

## 📋 SCHRITT 5: DATENBANK-SCHEMA INSTALLIEREN

```bash
cd C:\Users\manue\weltenbibliothek-backend

# Schema installieren
wrangler d1 execute weltenbibliothek-db --file=d1_schema_v3.3.0.sql --remote
```

---

## 📋 SCHRITT 6: JWT SECRET SETZEN

```bash
wrangler secret put JWT_SECRET
```

Wenn gefragt, eingeben:
```
WELTENBIBLIOTHEK_SECRET_KEY_2024_SECURE
```

---

## 📋 SCHRITT 7: WORKER DEPLOYEN

```bash
wrangler deploy
```

✅ **FERTIG! Backend läuft!**

---

## 🧪 SCHRITT 8: TESTEN

```bash
# Health Check
curl https://weltenbibliothek-backend.DEIN_ACCOUNT.workers.dev/health
```

Sollte zurückgeben:
```json
{"status":"healthy","timestamp":1234567890}
```

---

## ❓ WAS JETZT?

Sag mir, bei welchem Schritt du Hilfe brauchst!

Oder soll ich dir die 4 Dateien als Download-Paket erstellen?

