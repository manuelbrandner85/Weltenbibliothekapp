# 🧪 RECHERCHE-TOOL v1.0 - BEREIT ZUM TESTEN

## ✅ SYSTEM-STATUS: ONLINE

**Letzte Prüfung:** 2026-01-04 15:17 UTC  
**Status:** Alle Komponenten funktionieren

---

## 🌐 WEB-PREVIEW

**Test-URL:**
```
https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
```

### So testest du im Browser:
1. **URL öffnen** (siehe oben)
2. **Navigation:** **MATERIE** (Tab) → **Recherche** (zweiter Tab)
3. **Suchbegriff eingeben** z.B.:
   - "Berlin"
   - "Deutschland"
   - "Pharmaindustrie"
   - "Ukraine"
4. **"Recherche starten"** klicken
5. **Warten** (2-8 Sekunden, je nach Datenmenge)
6. **Scrollen** um die vollständige Analyse zu sehen

---

## 📱 ANDROID APK

**APK-Datei:** `app-release.apk`  
**Größe:** 93 MB  
**Version:** v1.0  
**Package:** com.dualrealms.knowledge

**Download-Link:**
```
https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=d798d27a-c038-4d89-b7e1-91560b1b7bfd&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=weltenbibliothek-recherche-v1.0.apk
```

### Installation auf Android:
1. **APK herunterladen** (Link oben)
2. **Auf Android-Gerät übertragen** (USB, Cloud, E-Mail)
3. **Einstellungen** → **Sicherheit** → **Unbekannte Quellen erlauben**
4. **APK-Datei öffnen** und installieren
5. **App starten**

### Nutzung auf Android:
- **Gleiche Schritte wie Web-Preview** (siehe oben)
- App-Icon: "Weltenbibliothek"
- **MATERIE** → **Recherche** → Suchbegriff eingeben → **Recherche starten**

---

## 🔧 CLOUDFLARE WORKER

**Worker-URL:**
```
https://weltenbibliothek-worker.brandy13062.workers.dev
```

**Status:** ✅ ONLINE

### Verifikations-Tests (alle bestanden):

**Test 1: Real-World-Begriff (Berlin)**
```bash
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin"
```
**Ergebnis:**
- Status: ok
- Query: Berlin
- Analyse vorhanden: ✅
- Analyse mitDaten: ✅
- Inhalt Länge: 1945 Zeichen

**Test 2: Real-World-Begriff (Deutschland)**
```bash
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Deutschland"
```
**Ergebnis:**
- Status: ok
- Wikipedia-Daten: ✅ (4000+ Zeichen)
- Internet Archive: ✅ (3 Treffer)
- PDF-Hints: ✅ (3 URLs)
- KI-Analyse: ✅ (1900+ Zeichen)

**Test 3: Nonsens-Begriff (Xyzabc123)**
```bash
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Xyzabc123"
```
**Ergebnis:**
- Status: ok
- Fallback-Analyse: ✅
- Disclaimer wird angezeigt: ✅

---

## 📋 ERWARTETE AUSGABE

### Bei guten Daten (z.B. "Berlin", "Deutschland"):
```
═══════════════════════════════════
RECHERCHE: Berlin
═══════════════════════════════════

1. KURZÜBERBLICK:
Berlin ist die Hauptstadt und größte Stadt 
Deutschlands mit etwa 3,7 Millionen Einwohnern...

2. GESICHERTE FAKTEN:
🔹 Berlin ist die Hauptstadt der BRD
🔹 Einwohnerzahl: ca. 3,7 Millionen
🔹 Fläche: 891,8 km²
...

3. AKTEURE & STRUKTUREN:
- Senat von Berlin (Landesregierung)
- Bundestag (Bundespolitik)
...

4. MEDIEN- & DARSTELLUNGSANALYSE:
Dominante Begriffe: "Hauptstadt", "Metropole"
Darstellungsweise: neutral-faktisch...

5. ALTERNATIVE EINORDNUNG:
Berlin als Symbol der deutschen Teilung und 
Wiedervereinigung...

6. WIDERSPRÜCHE & OFFENE FRAGEN:
- Spannungen zwischen historischer Bedeutung 
  und aktuellen Herausforderungen
...

7. GRENZEN DER RECHERCHE:
- Fehlende Echtzeitdaten zu Stadtentwicklung
- Lokale Debatten nicht vollständig abgebildet
...

─────────────────────────────────
Timestamp: 2026-01-04 15:17:23
```

### Bei schlechten/fehlenden Daten:
```
═══════════════════════════════════
RECHERCHE: Xyzabc123
═══════════════════════════════════

⚠️ ANALYSE OHNE AUSREICHENDE PRIMÄRDATEN

Für den Suchbegriff "Xyzabc123" konnten keine 
ausreichenden Primärdaten ermittelt werden.

Theoretische Einordnung:
[...]

─────────────────────────────────
Timestamp: 2026-01-04 15:17:45
```

---

## 🎯 TEST-SZENARIEN

### Empfohlene Test-Begriffe:

**Real-World-Begriffe (erwarten gute Daten):**
- ✅ "Berlin"
- ✅ "Deutschland"
- ✅ "Pharmaindustrie"
- ✅ "Ukraine Krieg"
- ✅ "NATO"
- ✅ "Europäische Union"

**Grenzfälle (erwarten Fallback):**
- ⚠️ "Xyzabc123" (Nonsens)
- ⚠️ "asdfghjkl" (Tastaturanschlag)
- ⚠️ "12345" (Nur Zahlen)

**Spezialthemen (testen Tiefe der Analyse):**
- 🔍 "MK Ultra"
- 🔍 "Operation Gladio"
- 🔍 "Bilderberg Konferenz"
- 🔍 "Rothschild Familie"

---

## 📊 TECHNISCHE DETAILS

### System-Architektur:
```
[Nutzer] 
   ↓
[Flutter App]
   ↓ HTTP GET ?q=BEGRIFF
[Cloudflare Worker]
   ↓ ↓ ↓
[Wikipedia] [Archive.org] [PDF-Hints]
   ↓ ↓ ↓
[Datensammlung]
   ↓
[@cf/meta/llama-3.1-8b-instruct]
   ↓
[7-Punkte-Analyse]
   ↓
[JSON-Response]
   ↓
[Flutter UI: Formatierte Darstellung]
```

### Performance:
- **Durchschnittliche Response-Zeit:** 2-8 Sekunden
- **Datenquellen-Timeout:** 5 Sekunden pro Quelle
- **KI-Analyse-Zeit:** 1-3 Sekunden
- **Gesamt-Timeout:** 10 Sekunden (Flutter)

### Fehlerbehandlung:
- **Worker nicht erreichbar:** "Worker nicht erreichbar"
- **Ungültiger Status:** "Ungültige Worker-Antwort"
- **Netzwerk-Fehler:** "Fehler: [Details]"
- **Timeout:** Automatischer Abbruch nach 10 Sekunden

---

## ✅ PRE-TEST CHECKLIST

**Vor dem Test prüfen:**
- ✅ Cloudflare Worker: ONLINE
- ✅ Web-Preview: ONLINE
- ✅ APK gebaut: JA
- ✅ APK Download-Link: AKTIV
- ✅ Test-Szenarien: DOKUMENTIERT

---

## 🚀 JETZT TESTEN!

### Option 1: Web-Preview (SCHNELL)
1. Öffne: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
2. MATERIE → Recherche
3. Suchbegriff: "Berlin"
4. Recherche starten
5. **Sag mir, was du siehst!**

### Option 2: Android APK (VOLLSTÄNDIG)
1. APK herunterladen (Link oben)
2. Auf Android installieren
3. App öffnen → MATERIE → Recherche
4. Suchbegriff: "Deutschland"
5. Recherche starten
6. **Sag mir, was du siehst!**

---

🎯 **Wähle eine Test-Option und teste JETZT!**

Berichte mir **genau**, was du siehst:
- ✅ Funktioniert es?
- ❌ Gibt es Fehler?
- 📷 Mach gerne Screenshots!

Ich warte auf dein Feedback! 🚀
