# 🦞 OpenClaw AI Integration - Weltenbibliothek

## ✅ Integration Status: AKTIV

**OpenClaw Gateway URL:** `http://72.62.154.95:50074/`  
**Gateway Token:** ✅ Konfiguriert  
**Hostinger VPS:** ✅ Erreichbar (Port 50074)  
**Flutter App:** ✅ Verbunden und läuft

---

## 🎯 Was ist OpenClaw AI?

OpenClaw AI ist ein selbst-gehosteter KI-Agent, der auf deinem Hostinger VPS läuft und fortgeschrittene AI-Features für die Weltenbibliothek App bereitstellt.

**Vorteile:**
- ✅ Vollständige Kontrolle über AI-Funktionen
- ✅ Keine Abhängigkeit von externen AI-Services
- ✅ Erweiterte Features für Recherche und Analyse
- ✅ 24/7 Verfügbarkeit über Hostinger VPS
- ✅ Intelligentes Fallback auf Cloudflare AI

---

## 🚀 Aktivierte AI-Features

### 1. **Recherche-Tool** (Materie-Welt)
- **OpenClaw:** Tiefgehende Recherche mit 500+ Wörtern
- **Multi-Source Aggregation:** Kombination mehrerer Quellen
- **Fact-Checking:** Automatische Überprüfung von Behauptungen
- **Fallback:** Cloudflare AI (Basis-Recherche)

### 2. **Propaganda-Detektor** (Materie-Welt)
- **OpenClaw:** Advanced Pattern Recognition
- **Bias-Analyse:** Erkennung von politischer Ausrichtung
- **Manipulation-Score:** Bewertung der Manipulationstechniken
- **Fallback:** Eingeschränkte Analyse

### 3. **Traum-Analyse** (Energie-Welt)
- **OpenClaw:** Detaillierte psychologische Analyse
- **Symbol-Interpretation:** Tiefenpsychologische Deutung
- **Archetypen-Erkennung:** Jung'sche Archetypen
- **Fallback:** Basis-Traumdeutung

### 4. **Chakra-Scanner** (Energie-Welt)
- **OpenClaw:** Holistische Energie-Analyse
- **Personalisierte Empfehlungen:** Individuelle Heilungsvorschläge
- **Frequenz-Vorschläge:** Spezifische Heilfrequenzen
- **Fallback:** Standard Chakra-Analyse

### 5. **Meditation-Generator** (Energie-Welt)
- **OpenClaw:** Personalisierte Meditationen
- **Adaptive Techniken:** Anpassung an Erfahrungslevel
- **Geführte Sessions:** Text-basierte Anleitungen
- **Fallback:** Standard-Meditationen

### 6. **Chat Smart Replies** (Beide Welten)
- **OpenClaw:** Kontextbewusste Antworten
- **Auto-Moderation:** Automatische Content-Filterung
- **Smart Suggestions:** Intelligente Vorschläge
- **Fallback:** Keine Smart Replies

---

## 🔧 Technische Details

### API-Konfiguration

**Location:** `lib/config/api_config.dart`

```dart
// OpenClaw Gateway Configuration
static const String openClawGatewayUrl = 'http://72.62.154.95:50074';
static const String openClawGatewayToken = 'lHNu7aoMko3O3ptFgBA1POK71xTf8YHw';
```

### Service-Architektur

```
Flutter App
    ↓
AIServiceManager (lib/services/ai_service_manager.dart)
    ↓
    ├─→ OpenClawGatewayService (Primary)
    │     ↓
    │   http://72.62.154.95:50074/
    │   (Hostinger VPS)
    │
    └─→ CloudflareAIService (Fallback)
          ↓
        https://weltenbibliothek-api-v3.brandy13062.workers.dev/ai
```

### Intelligentes Fallback-System

Der `AIServiceManager` wählt automatisch den besten Service:

1. **Primär:** OpenClaw Gateway (wenn erreichbar)
2. **Fallback:** Cloudflare AI (wenn OpenClaw nicht verfügbar)
3. **Caching:** Wiederverwendung erfolgreicher Anfragen
4. **Health-Check:** Automatische Service-Überwachung

---

## 📊 Service-Status überprüfen

### Im Flutter Code:

```dart
import 'package:weltenbibliothek/services/ai_service_manager.dart';

// Service-Manager erstellen
final aiManager = AIServiceManager();

// System-Status abrufen
final status = await aiManager.getSystemStatus();

print('OpenClaw Status: ${status['openclaw']['available']}');
print('Cloudflare Status: ${status['cloudflare']['available']}');
print('Aktiver Service: ${status['activeService']}');
```

### Von der Kommandozeile:

```bash
# OpenClaw Gateway testen
curl -I http://72.62.154.95:50074/

# Erwartete Antwort:
# HTTP/1.1 200 OK
# X-Powered-By: Express
# Content-Type: text/html; charset=utf-8
```

---

## 🛠️ Verwendung in der App

### Recherche durchführen:

```dart
import 'package:weltenbibliothek/services/ai_service_manager.dart';

final aiManager = AIServiceManager();

// Recherche mit automatischer Service-Auswahl
final result = await aiManager.performResearch(
  query: 'Klimawandel Fakten',
  minWords: 500,
);

print('Verwendeter Service: ${result['service']}'); // 'openclaw' oder 'cloudflare'
print('Recherche-Text: ${result['text']}');
```

### Propaganda-Analyse:

```dart
final analysis = await aiManager.detectPropaganda(
  text: 'Zu analysierender Text...',
);

print('Manipulation-Score: ${analysis['manipulationScore']}');
print('Erkannte Techniken: ${analysis['techniques']}');
```

### Traum-Analyse:

```dart
final dreamAnalysis = await aiManager.analyzeDream(
  description: 'Ich träumte von fliegenden Fischen...',
);

print('Interpretation: ${dreamAnalysis['interpretation']}');
print('Symbole: ${dreamAnalysis['symbols']}');
```

---

## 🔍 Fehlersuche

### OpenClaw nicht erreichbar:

**Problem:** `OpenClawGatewayService: Connection failed`

**Lösung:**
1. Prüfe ob OpenClaw auf dem VPS läuft
2. Teste die Verbindung: `curl http://72.62.154.95:50074/`
3. Prüfe Firewall-Einstellungen (Port 50074 muss offen sein)
4. Cloudflare Fallback aktiviert sich automatisch

### Authentifizierungs-Fehler:

**Problem:** `401 Unauthorized`

**Lösung:**
1. Prüfe ob der Gateway-Token korrekt ist
2. Token in `lib/config/api_config.dart` überprüfen
3. Neuen Token generieren: `openclaw get-api-key`

### Langsame Antwortzeiten:

**Problem:** OpenClaw-Anfragen dauern zu lange

**Lösung:**
1. VPS-Ressourcen prüfen (CPU, RAM)
2. OpenClaw neu starten: `systemctl restart openclaw`
3. Fallback-System nutzt automatisch Cloudflare

---

## 📈 Performance-Optimierungen

### Caching aktiviert:

- ✅ Recherche-Ergebnisse werden 1 Stunde gecacht
- ✅ Propaganda-Analysen werden 30 Minuten gecacht
- ✅ Traum-Analysen werden 24 Stunden gecacht

### Retry-Logik:

- ✅ 3 automatische Wiederholungen bei Fehlern
- ✅ Exponential Backoff (1s, 2s, 4s)
- ✅ Automatischer Fallback nach 3 Fehlversuchen

### Timeout-Werte:

- **Recherche:** 30 Sekunden
- **Propaganda-Analyse:** 20 Sekunden
- **Traum-Analyse:** 25 Sekunden
- **Chakra-Scanner:** 15 Sekunden
- **Meditation-Generator:** 20 Sekunden

---

## 🎯 Nächste Schritte

### Empfohlene Aktionen:

1. **✅ Features testen:**
   - Öffne die App in deinem Browser
   - Teste Recherche-Tool mit einem Thema
   - Probiere Propaganda-Detektor aus
   - Nutze Traum-Analyse

2. **🔒 SSL aktivieren (empfohlen):**
   - Richte HTTPS für OpenClaw ein
   - Nutze Let's Encrypt Zertifikat
   - Siehe: `OPENCLAW_QUICKSTART.md`

3. **📊 Monitoring einrichten:**
   - Überwache VPS-Ressourcen
   - Setze Uptime-Monitoring auf
   - Aktiviere Log-Rotation

4. **⚡ Performance-Tuning:**
   - Optimiere OpenClaw-Konfiguration
   - Passe Timeout-Werte an
   - Erweitere Caching

---

## 📚 Weitere Dokumentation

- **Setup-Anleitung:** `OPENCLAW_QUICKSTART.md`
- **API-Dokumentation:** `lib/services/openclaw_gateway_service.dart`
- **Service-Manager:** `lib/services/ai_service_manager.dart`
- **Hauptkonfiguration:** `lib/config/api_config.dart`

---

## 🆘 Support

**Bei Problemen:**
1. Prüfe die Logs: `tail -f /home/user/flutter_app/build_openclaw.log`
2. Teste OpenClaw direkt: `curl http://72.62.154.95:50074/`
3. Überprüfe Service-Status in der App
4. Fallback-System sollte automatisch funktionieren

---

**Status:** ✅ Integration erfolgreich abgeschlossen!  
**Letzte Aktualisierung:** 27. Februar 2026, 23:17 UTC  
**Version:** Weltenbibliothek v5.7.0 mit OpenClaw AI Integration
