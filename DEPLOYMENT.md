# 🚀 Weltenbibliothek V5.7.0 - Deployment Guide

**Version**: 5.7.0 (Build 57)  
**Release Date**: 2026-02-13  
**Package**: com.weltenbibliothek.v49  
**Size**: 122 MB

---

## 📦 **DEPLOYMENT ÜBERSICHT**

### **1. Flutter Mobile App (Android APK)**

**Build Info:**
- **Version**: 5.7.0
- **Build Number**: 57
- **Target SDK**: Android 36
- **Minimum SDK**: Android 21 (Lollipop)
- **File Size**: 122 MB
- **Build Type**: Release (Production-ready)

**APK Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

**Installation:**
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or manually transfer to device and install
```

---

### **2. Cloudflare Worker API (Backend)**

**Worker URL:** https://weltenbibliothek-api-v2.brandy13062.workers.dev

**Version:** 2.4.0  
**Deployment:** Cloudflare Workers  
**Storage:** D1 Database (SQLite)  
**AI Engine:** Cloudflare AI (@cf/meta/llama-3.1-8b-instruct)

**Configuration Files:**
- `wrangler-v2.toml` - Worker configuration
- `master_worker_v2.4_extended.js` - Main worker code (20.60 KiB)

**Bindings:**
- D1 Database: `weltenbibliothek-db` (UUID: 4fbea23c-8c00-4e09-aebd-2b4dceacbce5)
- Cloudflare AI: Enabled

**Deployment Command:**
```bash
cd /home/user/flutter_app
wrangler deploy --config wrangler-v2.toml
```

**Re-deployment:**
```bash
export CLOUDFLARE_API_TOKEN="your_token"
wrangler deploy --config wrangler-v2.toml
```

---

### **3. D1 Database**

**Database Name:** weltenbibliothek-db  
**Database ID:** 4fbea23c-8c00-4e09-aebd-2b4dceacbce5  
**Type:** SQLite (Cloudflare D1)  
**Size:** 593,920 bytes

**Schema:**
```sql
CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  realm TEXT NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  message TEXT NOT NULL,
  avatar_emoji TEXT DEFAULT '👤',
  avatar_url TEXT,
  timestamp TEXT NOT NULL,
  edited INTEGER DEFAULT 0,
  edited_at TEXT,
  deleted INTEGER DEFAULT 0,
  deleted_at TEXT,
  reply_to TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**Current Data:**
- Total Messages: 19
- Rooms: general, politik, energie
- Realms: materie, energie

**Database Operations:**
```bash
# Query database (local)
wrangler d1 execute weltenbibliothek-db --local --command="SELECT COUNT(*) FROM chat_messages"

# Query database (remote)
wrangler d1 execute weltenbibliothek-db --remote --command="SELECT COUNT(*) FROM chat_messages"

# Initialize with SQL file
wrangler d1 execute weltenbibliothek-db --remote --file=init_chat_db.sql
```

---

## 🆕 **NEUE FEATURES (V5.7.0)**

### **Bug Fixes**
✅ Image Forensics Cache-Problem gelöst  
✅ Propaganda Detector Offline-Warning behoben  
✅ Chat Grey Box Problem gelöst (API implementiert)

### **AI Features (17 neue Funktionen)**

#### **Energie-Welt**
1. **Traum-Analyse** - `POST /api/ai/dream-analysis`
2. **Chakra-Empfehlungen** - `POST /api/ai/chakra-advice`
3. **Meditation-Generator** - `POST /api/ai/meditation-script`

#### **Analyse & Insights**
4. **Netzwerk-Analyse** - `POST /api/ai/network-analysis`
5. **Fakten-Check** - `POST /api/ai/fact-check`
6. **Zeitstrahl-Generator** - `POST /api/ai/timeline`

#### **Sprache & Übersetzung**
7. **Echtzeit-Übersetzung** - `POST /api/ai/translate`
8. **Sprach-Erkennung** - `POST /api/ai/detect-language`

#### **Image & Media**
9. **Bildbeschreibung** - `POST /api/ai/image-describe`
10. **Bild-Kategorisierung** - `POST /api/ai/image-classify`

#### **Moderation**
11. **Auto-Moderation** - `POST /api/ai/moderate`

#### **Personalisierung**
12. **Content-Empfehlungen** - `POST /api/ai/content-recommend`

#### **Link Wrapper**
13. **Telegram-Wrapper** - `GET /go/tg/{username}`
14. **External-Link-Wrapper** - `GET /out?url={url}`
15. **Media-Proxy** - `GET /media?src={url}`

### **Recherche Tool Verbesserungen**
✅ AI-generierte offizielle Texte (500+ Wörter)  
✅ AI-generierte alternative Perspektiven (500+ Wörter)  
✅ Echte Telegram-Kanäle (25 Kanäle Datenbank)  
✅ Intelligente Kanal-Auswahl basierend auf Query

---

## 📡 **API ENDPOINTS**

### **Base URL**
```
https://weltenbibliothek-api-v2.brandy13062.workers.dev
```

### **Core Endpoints**

#### **Health Check**
```bash
GET /
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "service": "Weltenbibliothek API v2",
  "version": "2.4.0",
  "features": { ... }
}
```

#### **Recherche (Enhanced)**
```bash
POST /recherche
Content-Type: application/json

{
  "query": "Great Reset WEF",
  "perspective": "alternative",
  "depth": "deep"
}
```

**Response:**
```json
{
  "success": true,
  "scraper_status": "daten_gefunden",
  "sources": [
    {
      "title": "Offizielle Perspektive: Great Reset WEF",
      "url": "...",
      "fullText": "500+ Wörter AI-generierter Text...",
      "perspective": "official"
    },
    {
      "title": "Alternative Perspektive: Great Reset WEF",
      "url": "...",
      "fullText": "500+ Wörter kritische Analyse...",
      "perspective": "alternative"
    }
  ],
  "telegram_channels": [
    {
      "name": "Great Reset Watch",
      "url": "https://weltenbibliothek-api-v2.brandy13062.workers.dev/go/tg/great_reset_watch"
    }
  ]
}
```

#### **Chat API**
```bash
# Get Messages
GET /api/chat/messages?room={room}&realm={realm}&limit={limit}

# Post Message
POST /api/chat/messages
Content-Type: application/json

{
  "room": "general",
  "realm": "materie",
  "user_id": "user123",
  "username": "Manuel",
  "message": "Hallo Weltenbibliothek!",
  "avatar_emoji": "👤"
}

# Edit Message
PUT /api/chat/messages/{messageId}

# Delete Message
DELETE /api/chat/messages/{messageId}
```

#### **AI Features**

**Traum-Analyse:**
```bash
POST /api/ai/dream-analysis
Content-Type: application/json

{
  "dream_text": "Ich flog über eine goldene Stadt..."
}
```

**Chakra-Empfehlungen:**
```bash
POST /api/ai/chakra-advice
Content-Type: application/json

{
  "symptoms": ["Müdigkeit", "Kreativitätsblock"],
  "energy_level": "niedrig"
}
```

**Übersetzung:**
```bash
POST /api/ai/translate
Content-Type: application/json

{
  "text": "Die Wahrheit wird ans Licht kommen",
  "target_lang": "en",
  "source_lang": "de"
}
```

**Netzwerk-Analyse:**
```bash
POST /api/ai/network-analysis
Content-Type: application/json

{
  "topic": "Great Reset WEF",
  "entities": ["Klaus Schwab", "Bill Gates", "WHO"]
}
```

**Fakten-Check:**
```bash
POST /api/ai/fact-check
Content-Type: application/json

{
  "statement": "Die WHO plant eine weltweite Pandemie-Diktatur",
  "perspective": "alternative"
}
```

**Link Wrapper:**
```bash
# Telegram Redirect
GET /go/tg/{username}
# → Redirects to https://t.me/{username}

# External Link Wrapper
GET /out?url={encoded_url}
# → Redirects to external URL with tracking

# Media Proxy
GET /media?src={encoded_url}
# → Returns proxied & cached media
```

---

## 🛠️ **DEVELOPMENT SETUP**

### **Prerequisites**
- Flutter 3.35.4
- Dart 3.9.2
- Android SDK (API Level 36)
- Node.js 18+
- Wrangler CLI

### **Installation**

1. **Clone Repository:**
```bash
git clone <repository-url>
cd flutter_app
```

2. **Install Flutter Dependencies:**
```bash
flutter pub get
```

3. **Install Wrangler (Cloudflare):**
```bash
npm install -g wrangler
```

4. **Configure Cloudflare:**
```bash
# Login to Cloudflare
wrangler login

# Or use API token
export CLOUDFLARE_API_TOKEN="your_token"
```

### **Local Development**

**Flutter Web Preview:**
```bash
cd /home/user/flutter_app
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```

**Cloudflare Worker Local:**
```bash
wrangler dev --config wrangler-v2.toml
```

### **Building**

**Android APK:**
```bash
flutter build apk --release --build-number=57 --build-name="5.7.0"
```

**Android AAB (Play Store):**
```bash
flutter build appbundle --release --build-number=57 --build-name="5.7.0"
```

### **Testing**

**Unit Tests:**
```bash
flutter test
```

**Integration Tests:**
```bash
flutter test integration_test/
```

**API Tests:**
```bash
# Test all endpoints
./test_all_endpoints_v2.sh
```

---

## 📚 **FLUTTER SERVICES**

### **1. ai_service_extended.dart**

**Import:**
```dart
import 'package:flutter_app/services/ai_service_extended.dart';
```

**Usage:**
```dart
// Traum-Analyse
final result = await AIServiceExtended.analyzeDream(
  dreamText: 'Ich flog über eine goldene Stadt...',
);

// Chakra-Empfehlungen
final advice = await AIServiceExtended.getChakraAdvice(
  symptoms: ['Müdigkeit', 'Kreativitätsblock'],
  energyLevel: 'niedrig',
);

// Übersetzung
final translation = await AIServiceExtended.translateText(
  text: 'Die Wahrheit wird ans Licht kommen',
  targetLang: 'en',
);

// Netzwerk-Analyse
final network = await AIServiceExtended.analyzeNetwork(
  topic: 'Great Reset WEF',
  entities: ['Klaus Schwab', 'Bill Gates'],
);
```

### **2. wrapper_service.dart**

**Import:**
```dart
import 'package:flutter_app/services/wrapper_service.dart';
```

**Usage:**
```dart
// Telegram-Link wrappen
final wrappedUrl = WrapperService.wrapTelegramLink('great_reset_watch');
// → https://weltenbibliothek-api-v2.brandy13062.workers.dev/go/tg/great_reset_watch

// External-Link wrappen
final safeUrl = WrapperService.wrapExternalLink('https://example.com');

// Auto-Wrap (erkennt Link-Typ automatisch)
final smartUrl = WrapperService.autoWrap('https://t.me/channel');

// Telegram-Kanäle nach Kategorie
final channels = WrapperService.getWrappedChannels('gesundheit');
// → [
//     {name: 'Impfschaden Deutschland', wrapped_url: '...'},
//     {name: 'Corona Ausschuss', wrapped_url: '...'},
//   ]
```

---

## 🔐 **SECURITY & BEST PRACTICES**

### **API Keys**
- Cloudflare API Token: Store in environment variable `CLOUDFLARE_API_TOKEN`
- Never commit tokens to Git
- Use `.env` files for local development (already in `.gitignore`)

### **Database Security**
- D1 Database access only through Worker
- No direct database connections from client
- Use proper authentication for write operations

### **Flutter Security**
- Release builds use ProGuard/R8 for code obfuscation
- SSL/TLS for all API communications
- Local data encryption with Hive

---

## 📊 **MONITORING & ANALYTICS**

### **Cloudflare Analytics**
Access Worker analytics at:
```
https://dash.cloudflare.com/
→ Workers & Pages
→ weltenbibliothek-api-v2
→ Analytics
```

**Metrics:**
- Requests per second
- Error rate
- CPU time
- D1 Database queries

### **Flutter Crashlytics**
Firebase Crashlytics is integrated for crash reporting:
- Real-time crash alerts
- Stack traces
- User impact analysis

---

## 🐛 **TROUBLESHOOTING**

### **APK Installation Failed**
```bash
# Check device connection
adb devices

# Uninstall old version first
adb uninstall com.weltenbibliothek.v49

# Reinstall
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### **Worker Deployment Failed**
```bash
# Check Wrangler login
wrangler whoami

# Re-authenticate
wrangler login

# Check configuration
wrangler deploy --config wrangler-v2.toml --dry-run
```

### **D1 Database Issues**
```bash
# Check database status
wrangler d1 list

# Verify table schema
wrangler d1 execute weltenbibliothek-db --remote --command="SELECT sql FROM sqlite_master WHERE type='table' AND name='chat_messages'"

# Reset database (CAUTION: Deletes all data)
wrangler d1 execute weltenbibliothek-db --remote --file=init_chat_db.sql
```

### **Flutter Build Issues**
```bash
# Clean build cache
flutter clean
rm -rf build/

# Update dependencies
flutter pub get

# Rebuild
flutter build apk --release
```

---

## 📞 **SUPPORT**

**Project Repository:** (GitHub URL after setup)  
**Worker API:** https://weltenbibliothek-api-v2.brandy13062.workers.dev  
**Documentation:** This file

**Contact:**
- GitHub Issues: For bug reports and feature requests
- Developer: Manuel Brandner

---

## 📄 **LICENSE**

(Add license information here)

---

**Last Updated:** 2026-02-13  
**Version:** 5.7.0 (Build 57)  
**Maintained by:** Manuel Brandner
