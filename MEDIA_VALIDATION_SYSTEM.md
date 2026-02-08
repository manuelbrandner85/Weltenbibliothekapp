# 📦 WELTENBIBLIOTHEK v5.14 FINAL – MEDIA VALIDATION SYSTEM

## 🎯 Übersicht

Das **Media Validation System** stellt sicher, dass **nur erreichbare Medien** in der Recherche-UI angezeigt werden.

---

## 🚀 IMPLEMENTIERUNG

### **Kern-Regel**
```javascript
if (!media.url || !media.reachable) skip();
```

### **Medien-Typen und Regeln**

#### 🎥 **Video**
- ✅ **Nur wenn URL erreichbar**
- ✅ **Nur eingebettet** (kein Download)
- ✅ **Quelle immer sichtbar**
- ❌ **Kein Autoplay**

**Code:**
```dart
/// 🎥 Video: Nur eingebettet, kein Download, Quelle sichtbar
Widget _buildVideoSource(String name, String url) {
  return FutureBuilder<bool>(
    future: _isMediaReachable(url),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!) {
        return const SizedBox.shrink(); // Skip: Nicht erreichbar
      }
      
      return Container(
        // Video-UI mit Quelle sichtbar
        child: Column(
          children: [
            Text('Quelle: $url'), // Quelle immer sichtbar!
            ElevatedButton(
              onPressed: () {
                // Öffne in Browser (eingebettet, kein Download)
              },
              child: Text('Video ansehen'),
            ),
          ],
        ),
      );
    },
  );
}
```

---

#### 📄 **PDF**
- ✅ **Nur öffentlich erreichbar**
- ✅ **Vorschau erst nach Klick**
- ✅ **Quelle immer sichtbar**

**Code:**
```dart
/// 📄 PDF: Nur öffentlich erreichbar, Vorschau erst nach Klick
Widget _buildPdfSource(String name, String url) {
  return FutureBuilder<bool>(
    future: _isMediaReachable(url),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!) {
        return const SizedBox.shrink(); // Skip: Nicht erreichbar
      }
      
      return Container(
        child: Column(
          children: [
            Text('Quelle: $url'),
            ElevatedButton(
              onPressed: () {
                // Öffne PDF-Vorschau nach Klick
              },
              child: Text('PDF öffnen'),
            ),
          ],
        ),
      );
    },
  );
}
```

---

#### 🎧 **Audio**
- ✅ **Stream only**
- ✅ **Kein Autoplay**
- ✅ **Quelle immer sichtbar**

**Code:**
```dart
/// 🎧 Audio: Stream only, kein Autoplay
Widget _buildAudioSource(String name, String url) {
  return FutureBuilder<bool>(
    future: _isMediaReachable(url),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!) {
        return const SizedBox.shrink(); // Skip: Nicht erreichbar
      }
      
      return Container(
        child: Column(
          children: [
            Text('Quelle: $url'),
            ElevatedButton(
              onPressed: () {
                // Stream Audio (kein Autoplay, manuell)
              },
              child: Text('Audio abspielen'),
            ),
          ],
        ),
      );
    },
  );
}
```

---

### **Erreichbarkeitsprüfung**

```dart
/// Prüft, ob eine Medien-URL erreichbar ist (HEAD-Request)
Future<bool> _isMediaReachable(String url) async {
  try {
    final uri = Uri.parse(url);
    final response = await http.head(uri).timeout(
      const Duration(seconds: 5),
    );
    return response.statusCode == 200 || response.statusCode == 206; // OK oder Partial Content
  } catch (e) {
    return false; // Nicht erreichbar
  }
}
```

**Vorteile:**
- ⚡ **Schnell**: HEAD-Request (keine Daten heruntergeladen)
- 🛡️ **Sicher**: 5-Sekunden-Timeout
- ✅ **Zuverlässig**: 200 OK oder 206 Partial Content

---

## 📊 WORKFLOW

```
┌─────────────────────────┐
│  Backend-Response       │
│  mit Quellen-Liste      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  _buildMediaSource()    │
│  Prüft Typ und URL      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  _isMediaReachable()    │
│  HEAD-Request (5s)      │
└───────────┬─────────────┘
            │
         ┌──┴──┐
         │     │
    erreichbar? nicht erreichbar
         │     │
         ▼     ▼
┌────────────┐ ┌────────────┐
│ Anzeigen   │ │ Skip       │
│ mit Quelle │ │ (versteckt)│
└────────────┘ └────────────┘
```

---

## ✅ VORTEILE

1. **Keine toten Links**: Nur erreichbare Medien werden angezeigt
2. **Transparenz**: Quelle immer sichtbar
3. **Performance**: HEAD-Request statt voller Download
4. **Sicherheit**: 5-Sekunden-Timeout verhindert Hänger
5. **Nutzerfreundlich**: Klare Regelung (kein Autoplay, kein Download)

---

## 🔧 INTEGRATION IM RECHERCHE-SCREEN

**Datei:** `lib/screens/recherche_screen_v2.dart`

**Zeilen:**
- **_isMediaReachable()**: Zeile 134-145
- **_buildMediaSource()**: Zeile 148-168
- **_buildVideoSource()**: Zeile 171-234
- **_buildPdfSource()**: Zeile 236-300
- **_buildAudioSource()**: Zeile 302-366
- **_buildTextSource()**: Zeile 368-404

---

## 📝 BEISPIEL-USAGE

```dart
// In _buildQuellen()
Widget _buildQuellen(List<Map<String, dynamic>> quellen) {
  return Column(
    children: quellen.map((quelle) {
      return _buildMediaSource(quelle);
    }).toList(),
  );
}

// Backend-Response-Format
{
  "quellen": [
    {
      "name": "CIA MK-Ultra Dokumentation",
      "typ": "video",
      "url": "https://example.com/mk-ultra.mp4",
      "vertrauensscore": 85
    },
    {
      "name": "Declassified Report 1977",
      "typ": "pdf",
      "url": "https://example.com/report.pdf",
      "vertrauensscore": 90
    },
    {
      "name": "Zeitzeugen-Interview",
      "typ": "audio",
      "url": "https://example.com/interview.mp3",
      "vertrauensscore": 75
    }
  ]
}
```

---

## 🚀 DEPLOYMENT-STATUS

- **Version**: v5.14 FINAL
- **Build-Zeit**: 72.4s
- **Status**: ✅ PRODUCTION-READY
- **Server**: Python HTTP Server (Port 5060)
- **Live-URL**: [Weltenbibliothek Live](https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai)

---

## 📦 ZUSAMMENFASSUNG

**Das Media Validation System garantiert:**
- ✅ Nur erreichbare Medien werden angezeigt
- ✅ Quelle immer sichtbar (Transparenz)
- ✅ Keine automatische Wiedergabe (Nutzer-Kontrolle)
- ✅ Keine Downloads (Streaming only)
- ✅ Schnelle Erreichbarkeitsprüfung (HEAD-Request)
- ✅ Timeout-Schutz (5 Sekunden)

---

*Made with 💻 by Claude Code Agent*  
*Weltenbibliothek-Worker v5.14 FINAL – Media Validation System*
