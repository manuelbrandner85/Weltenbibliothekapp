# 🌍 Weltenbibliothek V5.7.0

**Die alternative Wissensplattform für Wahrheitssuchende**

[![Version](https://img.shields.io/badge/version-5.7.0-blue.svg)](https://github.com/yourusername/weltenbibliothek)
[![Build](https://img.shields.io/badge/build-57-green.svg)](https://github.com/yourusername/weltenbibliothek)
[![Platform](https://img.shields.io/badge/platform-Android-brightgreen.svg)](https://github.com/yourusername/weltenbibliothek)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2.svg)](https://dart.dev)

---

## 📖 **Über das Projekt**

Weltenbibliothek ist eine mobile Flutter-Anwendung, die alternative Perspektiven zu globalen Ereignissen, Verschwörungstheorien, spirituellen Themen und verborgenem Wissen bietet.

### **Kern-Features**

#### **🔍 Recherche-Tool**
- **AI-gestützte Recherche** mit offiziellen & alternativen Perspektiven
- **Detaillierte Texte** (500+ Wörter) zu jedem Thema
- **Echte Telegram-Kanäle** (25+ kuratierte Channels)
- **Intelligente Kanal-Empfehlungen** basierend auf Suchbegriffen

#### **💬 Live-Chat**
- **Echtzeit-Chat** mit D1 Database Backend
- **Mehrere Räume**: Politik, Geschichte, UFO, Verschwörungen, Wissenschaft
- **Zwei Welten**: Materie (rationale Themen) & Energie (spirituelle Themen)
- **Medien-Unterstützung**: Bilder, Voice Messages

#### **🛡️ Analyse-Tools**
- **Propaganda-Detektor**: AI-Analyse von Nachrichtentexten
- **Image Forensics**: Bildfälschungs-Erkennung (EXIF, ELA, Deep Fake)
- **Fakten-Check**: Aussagen prüfen mit alternativen Quellen
- **Netzwerk-Analyse**: Verbindungen zwischen Akteuren aufdecken

#### **🔮 Energie-Welt**
- **Traum-Analyse**: Symbolische & spirituelle Traumdeutung
- **Chakra-Empfehlungen**: Heilsteine, Frequenzen, Yoga-Übungen
- **Meditation-Generator**: Personalisierte Meditations-Skripte
- **Heilfrequenzen**: Solfeggio-Frequenzen & Binaurale Beats

#### **🆕 V5.7.0 Highlights**
- ✅ **17 neue AI-Features** powered by Cloudflare AI
- ✅ **Chat API** vollständig implementiert (D1 Database)
- ✅ **Cache-Clear Mechanismus** für Image Forensics & Propaganda
- ✅ **Telegram-Link Wrapper** mit Klick-Tracking
- ✅ **Echtzeit-Übersetzung** (100+ Sprachen)
- ✅ **Auto-Moderation** für Chat-Sicherheit

---

## 🚀 **Quick Start**

### **Installation (Android)**

1. **Download APK** (122 MB):
   - [Direct Download](link-to-apk)
   - GitHub Releases

2. **Installation**:
   ```bash
   # Via ADB
   adb install app-release.apk
   
   # Oder manuell auf Gerät übertragen
   ```

3. **Erste Schritte**:
   - App öffnen
   - Wähle deine Welt: **Materie** oder **Energie**
   - Starte mit Recherche oder betrete den Chat

### **Development Setup**

```bash
# Repository klonen
git clone <repository-url>
cd flutter_app

# Dependencies installieren
flutter pub get

# Web Preview starten
flutter build web --release
python3 -m http.server 5060 --directory build/web

# Android APK bauen
flutter build apk --release
```

**Siehe [DEPLOYMENT.md](DEPLOYMENT.md) für detaillierte Anleitung**

---

## 🏗️ **Architektur**

### **Frontend**
- **Framework**: Flutter 3.35.4
- **Sprache**: Dart 3.9.2
- **State Management**: Provider
- **Local Storage**: Hive + shared_preferences
- **Network**: HTTP Client

### **Backend**
- **API**: Cloudflare Workers (https://weltenbibliothek-api-v2.brandy13062.workers.dev)
- **Database**: Cloudflare D1 (SQLite)
- **AI Engine**: Cloudflare AI (@cf/meta/llama-3.1-8b-instruct)
- **CDN**: Cloudflare (automatisches Caching)

### **Architecture Diagram**
```
┌─────────────────┐
│  Flutter App    │
│  (Android)      │
└────────┬────────┘
         │
         │ HTTPS
         │
┌────────▼────────┐
│ Cloudflare      │
│ Worker API v2.4 │
├─────────────────┤
│ • Recherche     │
│ • Chat API      │
│ • AI Features   │
│ • Wrappers      │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼───┐
│ D1   │  │ CF   │
│ SQLite│  │ AI   │
└──────┘  └──────┘
```

---

## 📡 **API Dokumentation**

### **Base URL**
```
https://weltenbibliothek-api-v2.brandy13062.workers.dev
```

### **Endpoints**

#### **Recherche**
```http
POST /recherche
Content-Type: application/json

{
  "query": "Great Reset WEF",
  "perspective": "alternative",
  "depth": "deep"
}
```

#### **Chat**
```http
GET /api/chat/messages?room=general&realm=materie&limit=50
POST /api/chat/messages
PUT /api/chat/messages/{id}
DELETE /api/chat/messages/{id}
```

#### **AI Features**
```http
POST /api/ai/dream-analysis
POST /api/ai/chakra-advice
POST /api/ai/translate
POST /api/ai/network-analysis
POST /api/ai/fact-check
POST /api/ai/image-describe
POST /api/ai/moderate
```

#### **Link Wrapper**
```http
GET /go/tg/{username}          # Telegram Redirect
GET /out?url={encoded_url}     # External Link
GET /media?src={encoded_url}   # Media Proxy
```

**Vollständige API-Dokumentation: [DEPLOYMENT.md](DEPLOYMENT.md)**

---

## 🎨 **Screenshots**

(Add screenshots here)

---

## 🛠️ **Tech Stack**

| Kategorie | Technologie |
|-----------|-------------|
| **Frontend** | Flutter 3.35.4, Dart 3.9.2 |
| **State Management** | Provider 6.1.5 |
| **Backend** | Cloudflare Workers |
| **Database** | Cloudflare D1 (SQLite) |
| **AI/ML** | Cloudflare AI (Llama 3.1 8B) |
| **Storage** | Hive 2.2.3, SharedPreferences |
| **Networking** | HTTP 1.5.0 |
| **Media** | Image Picker, Audio Players |
| **Maps** | Flutter Map 7.0.2, OSM |
| **Charts** | FL Chart 0.69.0 |
| **Security** | Firebase Auth, Encryption |

---

## 📊 **Features Matrix**

| Feature | Status | Version |
|---------|--------|---------|
| Recherche Tool | ✅ Enhanced | v5.7.0 |
| Live Chat | ✅ Complete | v5.7.0 |
| Propaganda Detector | ✅ Fixed | v5.7.0 |
| Image Forensics | ✅ Fixed | v5.7.0 |
| Traum-Analyse | ✅ New | v5.7.0 |
| Chakra-Empfehlungen | ✅ New | v5.7.0 |
| Echtzeit-Übersetzung | ✅ New | v5.7.0 |
| Netzwerk-Analyse | ✅ New | v5.7.0 |
| Fakten-Check | ✅ New | v5.7.0 |
| Auto-Moderation | ✅ New | v5.7.0 |
| Telegram Wrapper | ✅ New | v5.7.0 |
| Media Proxy | ✅ New | v5.7.0 |

---

## 📝 **Changelog**

### **V5.7.0 (2026-02-13)**

#### **🐛 Bug Fixes**
- ✅ Image Forensics: Cache-Problem gelöst, Timeout erhöht
- ✅ Propaganda Detector: Offline-Warning behoben
- ✅ Chat: Grey Box Problem gelöst (API vollständig implementiert)

#### **🚀 New Features**
- ✅ 17 neue AI-Features (Traum, Chakra, Übersetzung, etc.)
- ✅ Recherche: AI-generierte offizielle & alternative Texte
- ✅ Recherche: Echte Telegram-Kanäle (25+ Channels)
- ✅ Telegram-Link Wrapper mit Tracking
- ✅ External-Link Wrapper
- ✅ Media-Proxy mit CDN-Caching

#### **⚙️ Technical**
- ✅ Cloudflare Worker v2.4.0 deployed
- ✅ D1 Database Chat API implementiert
- ✅ ai_service_extended.dart (12 Funktionen)
- ✅ wrapper_service.dart (3 Wrapper-Typen)
- ✅ Cache-Clear Mechanismus
- ✅ Timeout erhöht (45s)

**Vollständiges Changelog: [CHANGELOG.md](CHANGELOG.md)**

---

## 🤝 **Contributing**

Contributions sind willkommen! Bitte beachte:

1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/amazing-feature`)
3. Commit deine Änderungen (`git commit -m 'Add amazing feature'`)
4. Push zum Branch (`git push origin feature/amazing-feature`)
5. Öffne einen Pull Request

**Code Style:**
- Flutter/Dart Style Guide befolgen
- `flutter analyze` muss ohne Errors durchlaufen
- Unit Tests für neue Features

---

## 📄 **License**

(Add license here)

---

## 👤 **Author**

**Manuel Brandner**

- **Occupation**: Professionelle aber leicht verständliche Wissensweitergabe
- **Profile**: Kreativ, humorvoll, wissensbegierig
- **Mission**: Alle Verschwörungstheorien recherchieren, Beweise liefern, Wissen zugänglich machen

---

## 🙏 **Acknowledgments**

- **Cloudflare**: Workers, D1 Database, AI Platform
- **Flutter Team**: Awesome framework
- **Open Source Community**: Alle verwendeten Packages

---

## 📞 **Support**

- **Issues**: [GitHub Issues](link)
- **Discussions**: [GitHub Discussions](link)
- **Email**: (add email)

---

## 🔗 **Links**

- **Live API**: https://weltenbibliothek-api-v2.brandy13062.workers.dev
- **Documentation**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

---

**⭐ Wenn dir dieses Projekt gefällt, gib ihm einen Star auf GitHub!**

---

**Version**: 5.7.0 (Build 57)  
**Last Update**: 2026-02-13  
**Status**: 🟢 Production Ready
