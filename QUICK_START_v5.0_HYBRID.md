# ⚡ WELTENBIBLIOTHEK v5.0 HYBRID – QUICK START GUIDE

**Zielgruppe:** Flutter-Entwickler & Power-User  
**Zeitaufwand:** 5 Minuten

---

## 🎯 SCHNELLSTART

### **Option 1: Standard-Modus** (empfohlen)
```bash
# Test-Request
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin"
```

**Erwartung:**
- ✅ HTTP 200 OK
- ✅ JSON-Response
- ✅ ~7s (erste Anfrage)
- ✅ ~0-1s (wiederholte Anfragen via Cache)

---

### **Option 2: Live-SSE-Modus** (Power-User)
```bash
# Test-Request mit Live-Updates
curl -N "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin&live=true"
```

**Erwartung:**
- ✅ HTTP 200 OK
- ✅ Server-Sent Events (Stream)
- ✅ 7 SSE-Nachrichten
- ✅ ~17s Gesamt-Dauer

---

## 📱 FLUTTER-INTEGRATION

### **Standard-Modus (1 Zeile)**
```dart
final response = await http.get(Uri.parse('https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin'));
final data = jsonDecode(response.body);
```

### **Live-SSE-Modus (Stream)**
```dart
final url = 'https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin&live=true';
final request = http.Request('GET', Uri.parse(url));
final streamedResponse = await http.Client().send(request);

await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
  // Live-Updates verarbeiten
  print(chunk);
}
```

---

## 🔄 MODE-TOGGLE (Flutter)

```dart
// In recherche_screen_hybrid.dart
bool _useLiveMode = false; // false = Standard, true = SSE

final url = _useLiveMode
    ? '${workerUrl}?q=${Uri.encodeComponent(query)}&live=true'
    : '${workerUrl}?q=${Uri.encodeComponent(query)}';
```

**UI-Element:**
```dart
Switch(
  value: _useLiveMode,
  onChanged: (value) => setState(() => _useLiveMode = value),
)
```

---

## 🧪 TESTING

### **Test 1: Cache-Performance**
```bash
# Erste Anfrage (MISS)
time curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin"
# Zweite Anfrage (HIT)
time curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin"
```

**Erwartung:** Zweite Anfrage 57x schneller!

### **Test 2: Live-SSE-Updates**
```bash
curl -N "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin&live=true" | grep "phase"
```

**Erwartung:** 7 Phasen-Updates sichtbar!

---

## 📊 PERFORMANCE-TIPPS

### ✅ **Verwende Standard-Modus wenn:**
- Schnelle Antworten wichtig sind
- Gleiche Anfrage mehrmals gestellt wird
- Kosten minimiert werden sollen

### ✅ **Verwende SSE-Modus wenn:**
- Live-Updates während Recherche gewünscht
- Debugging erforderlich ist
- Transparenz über Crawling-Prozess wichtig

---

## 🚦 RATE-LIMITING

**Limit:** 3 Requests pro 60 Sekunden (pro IP)  
**Response:** HTTP 429 mit `Retry-After: 60`

**Wichtig:** Cache-HITs zählen NICHT zum Rate-Limit!

---

## 📚 DOKUMENTATION

- `HYBRID_SSE_v5.0_FINAL.md` – Vollständiger Guide
- `RELEASE_NOTES_v5.0_HYBRID.md` – Release Notes
- `lib/screens/recherche_screen_hybrid.dart` – Flutter-Screen

---

## 🎯 NEXT STEPS

### **Option 1: Flutter-App testen**
```bash
cd /home/user/flutter_app
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

### **Option 2: Android-APK bauen**
```bash
cd /home/user/flutter_app
flutter build apk --release
```

---

**Erstellt:** 2025-01-04  
**Version:** v5.0 Hybrid  
**Fragen?** Siehe vollständige Dokumentation in `HYBRID_SSE_v5.0_FINAL.md`
