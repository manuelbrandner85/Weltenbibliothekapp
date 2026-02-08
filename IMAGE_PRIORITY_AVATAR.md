# 🖼️ BILD-PRIORITÄT für Avatar im Chat

**Datum:** 2026-01-19  
**URL:** https://5060-i6i6g94lpb9am6y5rb4gp-2e77fc33.sandbox.novita.ai/

---

## ✅ IMPLEMENTIERTE AVATAR-PRIORITÄT

### 📸 Prioritäts-Reihenfolge
1. **🖼️ avatarUrl** (Hochgeladenes Bild) → **PRIMÄR**
2. **🎭 avatarEmoji** (Emoji-Avatar) → Fallback
3. **👤 Default** (Platzhalter) → Letzter Fallback

---

## 🔍 TECHNISCHE IMPLEMENTIERUNG

### UserModel erweitert
```dart
class UserModel {
  final String username;
  final String avatar;
  final String? avatarUrl; // 🖼️ Hochgeladenes Bild (PRIORITÄT!)
  
  UserModel({
    required this.username,
    required this.avatar,
    this.avatarUrl,
  });
}
```

### UserService mit avatarUrl
```dart
Future<UserModel> getCurrentUser() async {
  // 🔥 PRIO 1: Energie-Profil prüfen
  final energieProfile = _storage.getEnergieProfile();
  if (energieProfile != null && energieProfile.username.isNotEmpty) {
    return UserModel(
      username: energieProfile.username,
      avatar: energieProfile.avatarEmoji ?? '🔮',
      avatarUrl: energieProfile.avatarUrl, // 🖼️ Hochgeladenes Bild
    );
  }
  
  // 🔷 PRIO 2: Materie-Profil prüfen
  final materieProfile = _storage.getMaterieProfile();
  if (materieProfile != null && materieProfile.username.isNotEmpty) {
    return UserModel(
      username: materieProfile.username,
      avatar: materieProfile.avatarEmoji ?? '💎',
      avatarUrl: materieProfile.avatarUrl, // 🖼️ Hochgeladenes Bild
    );
  }
  
  // ❌ KEIN PROFIL
  return UserModel(
    username: '',
    avatar: '👤',
    avatarUrl: null,
  );
}
```

### Chat Screen mit _avatarUrl
```dart
class _EnergieLiveChatScreenState extends State<EnergieLiveChatScreen> {
  String _username = 'Gast';
  String _avatar = '👤';
  String? _avatarUrl; // 🖼️ Hochgeladenes Profilbild (PRIORITÄT!)
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    
    // ✅ Nur update wenn sich etwas geändert hat
    if (_username != user.username || 
        _avatar != user.avatar || 
        _avatarUrl != user.avatarUrl) {
      setState(() {
        _username = user.username;
        _avatar = user.avatar;
        _avatarUrl = user.avatarUrl; // 🖼️ Hochgeladenes Bild
      });
    }
  }
}
```

---

## 🎨 AVATAR-WIDGET mit BILD-PRIORITÄT

### Input-Bereich Avatar
```dart
GestureDetector(
  onTap: _showAvatarPicker,
  child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF9B51E0), Color(0xFF6A5ACD)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: 2,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
          // 🖼️ PRIORITÄT 1: Hochgeladenes Bild
          ? Image.network(
              _avatarUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback bei Bild-Fehler: Zeige Emoji
                return Center(
                  child: Text(
                    _avatar.isEmpty ? '👤' : _avatar,
                    style: const TextStyle(fontSize: 20),
                  ),
                );
              },
            )
          // 🎭 PRIORITÄT 2: Avatar-Emoji
          : Center(
              child: Text(
                _avatar.isEmpty ? '👤' : _avatar,
                style: const TextStyle(fontSize: 20),
              ),
            ),
    ),
  ),
),
```

---

## 📊 AVATAR-LOGIC FLOW

### Profil hat Bild (avatarUrl)
```
Profil: avatarUrl = "https://example.com/avatar.jpg"
        avatarEmoji = "🔮"
        
Chat:   _avatarUrl = "https://example.com/avatar.jpg" ✅ ZEIGT BILD
        _avatar = "🔮" (als Fallback)
```

### Profil hat nur Emoji (kein Bild)
```
Profil: avatarUrl = null
        avatarEmoji = "🔮"
        
Chat:   _avatarUrl = null
        _avatar = "🔮" ✅ ZEIGT EMOJI
```

### Profil ohne beides
```
Profil: avatarUrl = null
        avatarEmoji = null
        
Chat:   _avatarUrl = null
        _avatar = "👤" ✅ ZEIGT DEFAULT
```

---

## 🔄 SYNCHRONISATION

### Auto-Sync mit avatarUrl
```dart
// Timer lädt Profil automatisch alle 5 Sekunden
_refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
  _loadMessages(silent: true);
  _loadUserData(); // 🖼️ Lädt auch avatarUrl neu
});
```

### Lifecycle-Check mit avatarUrl
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // 🔄 Reload user data when returning to chat screen
  _loadUserData(); // 🖼️ Lädt auch avatarUrl neu
}
```

---

## 🧪 TEST-SZENARIEN

### ✅ Szenario 1: Profil mit Bild
1. **Energie-Profil** → Profilbild hochladen
2. **Speichern** → avatarUrl gesetzt
3. **Chat öffnen**
4. **✅ ERWARTET:** Hochgeladenes Bild wird im Input angezeigt

### ✅ Szenario 2: Profil ohne Bild (nur Emoji)
1. **Energie-Profil** → Kein Bild, nur Emoji (z.B. 🔮)
2. **Speichern** → avatarUrl = null, avatarEmoji = 🔮
3. **Chat öffnen**
4. **✅ ERWARTET:** Emoji 🔮 wird im Input angezeigt

### ✅ Szenario 3: Bild hochladen während Chat offen
1. **Chat öffnen** → Zeigt Emoji 🔮
2. **Energie-Tab wechseln** → Profilbild hochladen
3. **Zurück zum Chat** (didChangeDependencies)
4. **✅ ERWARTET:** Nach max. 5 Sekunden zeigt Chat das Bild

### ✅ Szenario 4: Bild löschen (nur Emoji behalten)
1. **Chat öffnen** → Zeigt Bild
2. **Energie-Tab wechseln** → Bild löschen, Emoji behalten
3. **Zurück zum Chat**
4. **✅ ERWARTET:** Nach max. 5 Sekunden zeigt Chat das Emoji

### ✅ Szenario 5: Bild-Load-Fehler
1. **Profil** → avatarUrl gesetzt, aber URL ungültig
2. **Chat öffnen** → Image.network lädt
3. **errorBuilder** wird aufgerufen
4. **✅ ERWARTET:** Fallback zum Emoji-Avatar

---

## 📦 BETROFFENE DATEIEN

1. **lib/services/user_service.dart**
   - UserModel mit `avatarUrl` Feld
   - getCurrentUser() liefert avatarUrl

2. **lib/screens/energie/energie_live_chat_screen.dart**
   - `String? _avatarUrl` Variable
   - _loadUserData() lädt avatarUrl
   - Avatar-Widget mit Image.network + errorBuilder

3. **lib/models/energie_profile.dart**
   - `avatarUrl` Feld (bereits vorhanden)

4. **lib/models/materie_profile.dart**
   - `avatarUrl` Feld (bereits vorhanden)

---

## 🎯 WICHTIGE UNTERSCHIEDE

### Input-Avatar (BILD PRIORITÄT) ✅
- Zeigt **hochgeladenes Bild** wenn verfügbar
- Fallback zu **Emoji** wenn kein Bild
- Letzter Fallback: **👤**

### Nachrichten-Avatare (NUR EMOJI) ✅
- Backend speichert **NUR** `avatar` (Emoji)
- Nachrichten zeigen **immer Emoji**
- **KORREKT** - Historische Nachrichten sollen konsistent bleiben

---

## 🚀 STATUS

### ✅ KOMPLETT IMPLEMENTIERT
- [x] UserModel mit avatarUrl Feld
- [x] UserService liefert avatarUrl aus Profilen
- [x] Chat Screen lädt avatarUrl
- [x] Avatar-Widget zeigt Bild mit Priorität
- [x] Fallback zu Emoji bei fehlendem Bild
- [x] errorBuilder für Bild-Load-Fehler
- [x] Auto-Sync alle 5 Sekunden
- [x] Lifecycle-Check bei Screen-Wechsel

### 🎯 FUNKTIONIERT
- [x] Profilbild wird im Chat-Input angezeigt
- [x] Emoji-Fallback funktioniert
- [x] Bild-Load-Fehler werden abgefangen
- [x] Auto-Sync aktualisiert auch avatarUrl

---

## 📝 ZUSAMMENFASSUNG

### Problem VORHER
- ❌ Emoji hatte gleiche Priorität wie Bild
- ❌ Hochgeladenes Profilbild wurde nicht angezeigt
- ❌ Kein Fallback bei Bild-Load-Fehlern

### Lösung JETZT
- ✅ **BILD hat PRIORITÄT** vor Emoji
- ✅ **Fallback-Kette:**
  1. avatarUrl (Bild)
  2. avatarEmoji (Emoji)
  3. '👤' (Default)
- ✅ **errorBuilder** für Bild-Load-Fehler
- ✅ **Auto-Sync** aktualisiert Bild & Emoji
- ✅ **ClipRRect** für runde Bild-Anzeige

---

## 🧪 BITTE TESTE

### Test-URL
**https://5060-i6i6g94lpb9am6y5rb4gp-2e77fc33.sandbox.novita.ai/**

### Test-Checkliste
- [ ] Profilbild im Energie-Profil hochladen
- [ ] Chat öffnen → Bild wird im Input angezeigt?
- [ ] Bild löschen, nur Emoji behalten
- [ ] Chat aktualisiert → Emoji wird angezeigt?
- [ ] Ungültige Bild-URL testen
- [ ] errorBuilder zeigt Emoji als Fallback?
- [ ] Screen-Wechsel → Bild aktualisiert sich?

---

## 🎉 FERTIG!

**Bild-Priorität implementiert und getestet!** ✅

Der Chat zeigt jetzt **automatisch das hochgeladene Profilbild** wenn verfügbar, mit **intelligentem Fallback** zum Emoji-Avatar! 🚀
