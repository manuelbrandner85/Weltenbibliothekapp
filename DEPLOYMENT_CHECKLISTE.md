# ✅ DEPLOYMENT CHECKLISTE - WELTENBIBLIOTHEK v3.0.0

## 📋 PRE-DEPLOYMENT CHECKLIST

### **1. Cloudflare Setup**
- [ ] Cloudflare Account erstellt (https://dash.cloudflare.com/sign-up)
- [ ] Node.js installiert (für Wrangler CLI)
- [ ] Wrangler CLI installiert (`npm install -g wrangler`)
- [ ] Cloudflare Login erfolgreich (`wrangler login`)

### **2. Dateien überprüft**
- [ ] `cloudflare-worker/index.js` vorhanden (9.4 KB)
- [ ] `cloudflare-worker/wrangler.toml` vorhanden
- [ ] `cloudflare-worker/package.json` vorhanden
- [ ] `cloudflare-worker/.gitignore` vorhanden

---

## 🚀 DEPLOYMENT STEPS

### **SCHRITT 1: Worker deployen**

```bash
cd /home/user/flutter_app/cloudflare-worker
wrangler deploy
```

**Erwartete Ausgabe:**
```
✔ Uploaded weltenbibliothek-worker
✔ Published weltenbibliothek-worker (0.87 sec)
  https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev
```

- [ ] Worker deployed
- [ ] Worker-URL erhalten
- [ ] Worker-URL kopiert

**Deine Worker-URL:**
```
_________________________________________________
```

---

### **SCHRITT 2: Worker testen**

```bash
curl "https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Test"
```

**Erwartete Antwort:**
```json
{
  "query": "Test",
  "status": "completed",
  "quellen": [...],
  "analyse": {...}
}
```

- [ ] Test-Request erfolgreich
- [ ] JSON-Response erhalten
- [ ] Quellen-Array nicht leer
- [ ] Status = "completed"

---

### **SCHRITT 3: Flutter anpassen**

**Datei:** `/home/user/flutter_app/lib/services/backend_recherche_service.dart`

**Zeile 27 ändern:**

```dart
// ALT:
this.baseUrl = 'https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev',

// NEU (deine Worker-URL):
this.baseUrl = 'https://weltenbibliothek-worker.____HIER_EINTRAGEN____.workers.dev',
```

- [ ] `baseUrl` aktualisiert
- [ ] Worker-URL korrekt eingetragen
- [ ] Datei gespeichert

---

### **SCHRITT 4: Flutter neu bauen**

```bash
cd /home/user/flutter_app

# Cache löschen
rm -rf build/web .dart_tool/build_cache

# Neu bauen
flutter build web --release

# Web-Server starten
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

- [ ] Cache gelöscht
- [ ] Flutter Build erfolgreich
- [ ] Web-Server gestartet
- [ ] Port 5060 aktiv

---

### **SCHRITT 5: App testen**

**Flutter App URL:** `https://5060-...sandbox.novita.ai`

1. App öffnen
2. Suchbegriff eingeben: **"Ukraine Krieg"**
3. Button **RECHERCHE** klicken
4. Warten ~10-15 Sekunden
5. Ergebnisse prüfen

**Checkliste:**
- [ ] App geladen
- [ ] Recherche-Eingabe funktioniert
- [ ] RECHERCHE-Button funktioniert
- [ ] Loading-Indicator erscheint
- [ ] Progress-Updates sichtbar
- [ ] STEP 1 + STEP 2 abgeschlossen
- [ ] 7 Tabs anzeigbar
- [ ] ECHTE DATEN in Quellen-Liste
- [ ] Keine Mock-Daten!

---

## 🎨 VISUALISIERUNGS-CHECK

### **Tab 1: ÜBERSICHT**
- [ ] Mindmap sichtbar
- [ ] Hauptkennzahlen angezeigt
- [ ] KI-Disclaimer (falls KI-generiert)

### **Tab 2: MACHTANALYSE**
- [ ] Netzwerk-Graph angezeigt
- [ ] Machtindex-Chart sichtbar
- [ ] Akteure identifiziert

### **Tab 3: NARRATIVE**
- [ ] Narrative-Liste angezeigt
- [ ] Titel & Beschreibungen vorhanden

### **Tab 4: TIMELINE**
- [ ] Timeline-Visualisierung sichtbar
- [ ] Ereignisse chronologisch
- [ ] Icons & Relevanz-Balken

### **Tab 5: KARTE**
- [ ] OpenStreetMap geladen
- [ ] Marker sichtbar (falls Standorte vorhanden)
- [ ] Filter-Chips funktionieren

### **Tab 6: ALTERNATIVE**
- [ ] Alternative Sichtweisen angezeigt
- [ ] Titel & Thesen vorhanden

### **Tab 7: META**
- [ ] Meta-Kontext angezeigt
- [ ] Einordnung & Reflexion vorhanden

---

## 🔍 MONITORING SETUP

### **Cloudflare Dashboard**

```
https://dash.cloudflare.com/
→ Workers & Pages
→ weltenbibliothek-worker
```

**Prüfen:**
- [ ] Worker-Status: "Running"
- [ ] Requests in letzter Stunde
- [ ] Fehlerrate <1%
- [ ] Latenz <15s

### **Live Logs**

```bash
wrangler tail
```

- [ ] Live-Logs funktionieren
- [ ] Requests sichtbar
- [ ] Keine kritischen Fehler

---

## 🚨 TROUBLESHOOTING

### **Problem 1: Worker deployed, aber keine Daten in Flutter**

**Ursache:** `baseUrl` nicht aktualisiert

**Lösung:**
- [ ] `lib/services/backend_recherche_service.dart` öffnen
- [ ] Zeile 27: Worker-URL eintragen
- [ ] Flutter neu bauen

---

### **Problem 2: CORS-Fehler in Browser-Console**

**Ursache:** Worker-CORS-Headers fehlen

**Lösung:**
```bash
wrangler deploy  # Neu deployen
```
- [ ] Worker neu deployed
- [ ] CORS-Fehler behoben

---

### **Problem 3: Timeout nach 60 Sekunden**

**Ursache:** Worker braucht zu lange

**Lösung:**
1. Öffne `cloudflare-worker/index.js`
2. Zeile ~46: Reduziere Anzahl Quellen
3. Worker neu deployen

- [ ] `index.js` angepasst
- [ ] Worker neu deployed
- [ ] Timeout behoben

---

### **Problem 4: AI-Fehler in Worker-Logs**

**Ursache:** Cloudflare AI Free Tier überschritten

**Lösung:**
```
https://dash.cloudflare.com/ → AI → Usage
```
- [ ] Usage geprüft
- [ ] Free Tier: 10.000 Requests/Tag
- [ ] Fallback-Logic aktiv

---

## 💰 KOSTEN-CHECK

### **Cloudflare Free Tier**

| Service | Limit | Genutzt | Status |
|---------|-------|---------|--------|
| Workers Requests | 100.000/Tag | _____ | ✅ |
| AI Requests | 10.000/Tag | _____ | ✅ |
| Bandwidth | Unlimitiert | _____ | ✅ |

- [ ] Free Tier ausreichend
- [ ] Keine Kosten entstanden
- [ ] Monitoring eingerichtet

---

## 📊 PERFORMANCE-CHECK

### **Ziel-Metriken**

| Metrik | Ziel | Aktuell | Status |
|--------|------|---------|--------|
| Crawling-Zeit | <10s | _____ | |
| AI-Analyse | <5s | _____ | |
| Gesamt-Latenz | <15s | _____ | |
| Fehlerrate | <1% | _____ | |
| Uptime | >99% | _____ | |

- [ ] Performance-Ziele erreicht
- [ ] Latenz akzeptabel
- [ ] Fehlerrate niedrig

---

## ✅ FINAL CHECK

### **Funktionalität**
- [ ] Echte Webseiten werden gecrawlt
- [ ] KEINE Mock-Daten mehr
- [ ] KI-Analyse funktioniert
- [ ] Alle 7 Tabs anzeigbar
- [ ] Visualisierungen funktionieren

### **Qualität**
- [ ] Datenquellen divers (News, Archive, Enzyklopädie)
- [ ] Mindestens 3 Quellen pro Recherche
- [ ] KI extrahiert Akteure & Narrative
- [ ] UI responsive & benutzerfreundlich

### **Production-Ready**
- [ ] Worker in Production deployed
- [ ] Flutter App aktualisiert
- [ ] Monitoring eingerichtet
- [ ] Dokumentation vorhanden

---

## 🎉 DEPLOYMENT ABGESCHLOSSEN!

**Wenn alle Checkboxen ✅ sind:**

✅ **WELTENBIBLIOTHEK v3.0.0 IST LIVE!**

- ✅ Echte Webseiten-Crawls
- ✅ KI-gestützte Analyse
- ✅ Professionelle Visualisierung
- ✅ Kostenlos & skalierbar
- ✅ Production-ready

---

## 📚 NEXT STEPS

### **Optional:**

1. **Custom Domain** einrichten
   - Cloudflare DNS konfigurieren
   - Worker-Route zuweisen

2. **Analytics** erweitern
   - Cloudflare Analytics nutzen
   - Custom Events tracken

3. **Skalierung** planen
   - Workers Paid Plan bei >10k Req/Tag
   - Caching optimieren

---

**GRATULATION! DIE WELTENBIBLIOTHEK LIEFERT JETZT ECHTE DATEN!** 🎉📚🔍
