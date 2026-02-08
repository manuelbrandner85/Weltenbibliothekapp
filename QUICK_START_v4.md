# 🚀 QUICK START - Weltenbibliothek v4.0.0

**Fertig zum Deployment in 5 Minuten!**

---

## ⚡ SCHRITT 1: WORKER DEPLOYEN

```bash
cd /home/user/flutter_app/cloudflare-worker
wrangler deploy
```

**Expected Output**:
```
✓ Deployed to: https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev
```

**WICHTIG**: Kopiere diese URL! Du brauchst sie im nächsten Schritt.

---

## ⚡ SCHRITT 2: WORKER-URL KONFIGURIEREN

Öffne die Datei:
```
lib/services/backend_recherche_service.dart
```

Ändere Zeile 27:
```dart
// VORHER:
BackendRechercheService({
  this.baseUrl = 'http://localhost:8080',
});

// NACHHER:
BackendRechercheService({
  this.baseUrl = 'https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev',
});
```

**WICHTIG**: Ersetze `DEIN-USERNAME` mit deinem Cloudflare-Username!

---

## ⚡ SCHRITT 3: FLUTTER BAUEN

```bash
cd /home/user/flutter_app
flutter build web --release
```

**Expected Output**:
```
✓ Built build/web
```

---

## ⚡ SCHRITT 4: SERVER STARTEN

```bash
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

**Server läuft auf**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai

---

## 🎯 SCHRITT 5: LIVE TESTEN

### **1. Öffne die Preview-URL**:
🔗 https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai

### **2. Recherche starten**:
- Suchbegriff eingeben: **"Ukraine Krieg"**
- Klick auf **"Recherchieren"**

### **3. Warten** (10-15 Sekunden):
- Worker crawlt 5 Live-Quellen
- Cloudflare AI analysiert Texte
- Multimedia-URLs werden extrahiert

### **4. Ergebnis anschauen**:

**Tab 1 - ÜBERSICHT**:
- Haupt-Erkenntnisse
- Anzahl Akteure, Geldflüsse, Narrative
- Mindmap-Visualisierung

**Tab 2 - MULTIMEDIA** ← **NEU!**:
- 🎬 **Videos**: Klick → YouTube/Vimeo öffnet
- 📄 **PDFs**: Klick → Download/Browser
- 🖼️ **Bilder**: Klick → Vollbild-Dialog
- 🎧 **Audios**: Klick → Externe Player

**Tab 3 - MACHTANALYSE**:
- Akteure mit Machtindex
- Netzwerk-Graph
- Einflussbereiche

**Tab 4 - NARRATIVE**:
- Medienberichte
- Narrative-Analysen

**Tab 5 - TIMELINE**:
- Chronologie der Ereignisse
- Zeitstrahl-Visualisierung

**Tab 6 - KARTE**:
- Geo-Standorte
- OpenStreetMap-Integration

**Tab 7 - ALTERNATIVE**:
- Alternative Sichtweisen
- Kontroversen

**Tab 8 - META**:
- Meta-Kontext
- Quellenbewertung

---

## 🔍 DEBUG-TIPPS

### **Worker funktioniert nicht?**

**Test-Befehl**:
```bash
curl "https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Test"
```

**Expected Response**:
```json
{
  "query": "Test",
  "status": "success",
  "quellen": [...],
  "media": {
    "videos": [],
    "pdfs": [],
    "images": [],
    "audios": []
  },
  "analyse": {...}
}
```

### **Multimedia-Tab leer?**

**Prüfe Worker-Response**:
```bash
curl "https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Ukraine+Krieg" | jq '.media'
```

**Expected**:
```json
{
  "videos": [...],  // YouTube-URLs
  "pdfs": [...],    // PDF-Links
  "images": [...],  // Bild-URLs
  "audios": [...]   // Audio-URLs
}
```

### **Server läuft nicht?**

**Prüfe Port**:
```bash
lsof -i :5060
```

**Neu starten**:
```bash
pkill -f "python3 -m http.server"
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

---

## 📱 MOBILE-TEST

### **Browser DevTools öffnen** (F12):
1. **Responsive Design Mode** aktivieren
2. **Gerät wählen**: iPhone 12 Pro (390x844)
3. **Recherche durchführen**
4. **Multimedia-Tab öffnen**
5. **Bilder-Grid testen**: 3-Spalten-Layout
6. **Vollbild-Dialog testen**: Klick auf Bild

---

## 🎨 BEISPIEL-RECHERCHEN

### **Test 1: Multimedia-reiches Thema**
```
Suchbegriff: "Ukraine Krieg"
```
**Erwartete Medien**:
- Videos: YouTube-Nachrichtenclips
- PDFs: Forschungsberichte
- Bilder: Karten, Fotos
- Audios: Podcasts

### **Test 2: Wissenschaftliches Thema**
```
Suchbegriff: "Klimawandel IPCC"
```
**Erwartete Medien**:
- PDFs: IPCC-Berichte
- Bilder: Grafiken, Diagramme
- Videos: Wissenschafts-Videos

### **Test 3: Historisches Thema**
```
Suchbegriff: "Berliner Mauer 1989"
```
**Erwartete Medien**:
- Bilder: Historische Fotos
- Videos: Archiv-Material
- PDFs: Historische Dokumente

---

## 🔧 TROUBLESHOOTING

### **Problem: "Keine Multimedia-Inhalte gefunden"**

**Ursachen**:
1. Worker extrahiert keine URLs → Prüfe Worker-Logs
2. Quellen haben keine Medien → Andere Suchbegriffe testen
3. Media-Feld ist null → Prüfe Backend-Service

**Lösung**:
```bash
# Worker-Logs prüfen
wrangler tail

# Andere Recherche testen
curl "https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Ukraine"
```

### **Problem: "URL konnte nicht geöffnet werden"**

**Ursache**: `url_launcher` fehlt oder nicht konfiguriert

**Lösung**:
```bash
cd /home/user/flutter_app
flutter pub get
flutter build web --release
```

### **Problem: "Bilder werden nicht geladen"**

**Ursache**: CORS-Probleme oder kaputte URLs

**Lösung**:
- Bilder werden mit `errorBuilder` behandelt
- Zeigt "Broken Image"-Icon bei Fehlern
- Vollbild-Dialog mit Fehlermeldung

---

## 🎊 ERFOLG!

**Wenn alles funktioniert, siehst du**:

✅ Recherche startet automatisch  
✅ Progress-Indicator zeigt Fortschritt  
✅ 8 Tabs werden befüllt  
✅ Multimedia-Tab zeigt Videos/PDFs/Bilder/Audios  
✅ Klicks öffnen externe Links  
✅ Vollbild-Dialog für Bilder funktioniert  
✅ Mobile-Layout ist responsive  

---

## 📚 WEITERE DOKUMENTATION

- **INTEGRATION_COMPLETE_v4.md** - Vollständige Projektdokumentation
- **MULTIMEDIA_INTEGRATION_FINAL.md** - Multimedia-Features im Detail
- **CLOUDFLARE_WORKER_SETUP.md** - Worker-Konfiguration
- **STATUS_FINAL.md** - Projekt-Status und Features

---

**Status**: ✅ **READY TO USE**  
**Version**: v4.0.0  
**Deployment-Zeit**: ~5 Minuten  

🚀 **VIEL ERFOLG MIT DEINER WELTENBIBLIOTHEK!**
