# 📝 VERBLEIBENDE TODOs - WELTENBIBLIOTHEK V3.1

**Status**: Non-Critical (App ist funktionsfähig)  
**Letzte Aktualisierung**: 2026-02-14

---

## 🟡 NIEDRIGE PRIORITÄT (Nice-to-Have Features)

### 👤 User-Profile Integration
- `webrtc_call_provider.dart:207` - Username von UserProfile laden statt Hard-Coded "User"
- `frequency_session_screen.dart:221` - Hard-Coded `'user_manuel'` durch UserService ersetzen

### 🔔 Notification System
- `chat_room_screen.dart:382` - NotificationService für Mute-Status integrieren

### 📤 Share-Funktionen
- `archetype_compass_screen.dart:197` - Share-Funktion (Social Media, Export)
- `gematria_calculator_screen.dart:3440` - Image Export implementieren
- `community_tab_modern.dart:632` - Share-Funktion für Posts
- `community_tab_modern.dart:547` - Post-Optionen (Teilen, Melden, etc.)

### ⭐ Favorites & Likes
- `energie_community_tab.dart:497` - Favorites API neu implementieren
- `energie_community_tab.dart:629` - FavoritesService Static API
- `energie_community_tab.dart:834` - Tatsächlichen Like-Status laden
- `community_tab_modern.dart:622` - User-Like-Status prüfen

### 💬 Chat-Features (Erweitert)
- `energie_live_chat_screen.dart:1086` - Tool öffnen aus Chat
- `energie_live_chat_screen.dart:1236` - Scroll to Message
- `energie_live_chat_screen.dart:1652` - Thread-Reply implementieren
- `energie_live_chat_screen.dart:2258` - Typing-Update an Server senden
- `energie_live_chat_screen.dart:2301` - Visual Highlight-Effekt
- `energie_live_chat_screen.dart:2899` - Admin Delete via API

### 🎯 Achievement System
- `new_spirit_tool_screens.dart:2228` - Re-enable nach Achievement-Integration

### 🔮 Chakra System
- `chakra_scan_screen.dart:32` - Real-time Chakra State Tracking

### 🌐 Community Features
- `community_tab_modern.dart:730` - Community-Actions (Like, Comment, Share)

---

## ✅ BEREITS IMPLEMENTIERT (Kritische TODOs)

- ✅ Chat-Endpoint Backend-Integration (`/api/chat/messages`)
- ✅ UserService Integration für User-IDs
- ✅ Recherche-System Backend-API
- ✅ Intelligent Search Backend-Integration
- ✅ Chat Room Features (Notifications, Settings, Clear)
- ✅ API-Konfiguration mit korrekten Tokens

---

## 📊 ZUSAMMENFASSUNG

**Verbleibende TODOs**: ~20  
**Kritikalität**: Niedrig (App voll funktionsfähig)  
**Empfehlung**: Schrittweise Implementierung in zukünftigen Updates

**Prioritäten für nächste Releases**:
1. Share-Funktionen (Social Media Integration)
2. Favorites-API Modernisierung
3. Erweiterte Chat-Features (Threads, Mentions)
4. Admin-Funktionen via API

---

*Dokumentiert am: 2026-02-14*
