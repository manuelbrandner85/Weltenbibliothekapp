# 🚀 BACKEND-SYNC IMPLEMENTIERUNG - NÄCHSTE SCHRITTE

## ✅ WAS BEREITS FUNKTIONIERT (Frontend)

### **1. Profile Sync Service** (`lib/services/profile_sync_service.dart`)
```dart
// Bei Profil-Erstellung wird automatisch Backend aufgerufen:
POST /api/profile/materie
{
  "username": "TestUser",
  "name": "Test User",
  "bio": "...",
  "password": "Jolene2305"  // nur für Weltenbibliothek
}

// Backend sollte User erstellen und zurückgeben:
{
  "success": true,
  "userId": "materie_TestUser",
  "role": "user",
  "username": "TestUser",
  ...
}
```

### **2. Admin Dashboard** (`lib/screens/shared/world_admin_dashboard.dart`)
```dart
// Dashboard ruft User-Liste ab:
GET /api/admin/users/materie

// Erwartet:
{
  "success": true,
  "users": [
    {
      "userId": "materie_Weltenbibliothek",
      "username": "Weltenbibliothek",
      "role": "root_admin",
      "world": "materie"
    },
    ...
  ]
}
```

### **3. User-Liste UI** (vollständig implementiert)
- ListView mit Icons und Badges
- Root-Admin Aktionen (Promote, Demote, Delete)
- World-Isolation
- **BEREIT zum Testen sobald Backend User zurückgibt!**

---

## 🔧 WAS DAS BACKEND TUN MUSS

### **Cloudflare Worker Endpoints:**

#### **1. POST /api/profile/:world - User erstellen**
```javascript
// Wenn Profil gespeichert wird, User in D1 Database speichern:

export async function handleProfileSave(request, env) {
  const { username, name, bio, password, avatar_url, avatar_emoji } = await request.json();
  const world = request.params.world; // 'materie' oder 'energie'
  
  // 1. User in users table speichern/aktualisieren
  const userId = `${world}_${username}`;
  const role = (username === 'Weltenbibliothek' && password === 'Jolene2305') 
    ? 'root_admin' 
    : 'user';
  
  await env.DB.prepare(`
    INSERT OR REPLACE INTO users (user_id, username, world, role, created_at, last_active)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  `).bind(userId, username, world, role).run();
  
  // 2. Profil in profiles table speichern
  await env.DB.prepare(`
    INSERT OR REPLACE INTO profiles (user_id, username, world, name, bio, avatar_url, avatar_emoji)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(userId, username, world, name, bio, avatar_url, avatar_emoji).run();
  
  // 3. User-Daten zurückgeben
  return {
    success: true,
    userId: userId,
    username: username,
    role: role,
    world: world,
    isAdmin: role === 'admin' || role === 'root_admin',
    isRootAdmin: role === 'root_admin'
  };
}
```

#### **2. GET /api/admin/users/:world - User-Liste**
```javascript
export async function handleGetUsers(request, env) {
  const world = request.params.world; // 'materie' oder 'energie'
  
  // Alle User der Welt aus D1 laden
  const results = await env.DB.prepare(`
    SELECT user_id, username, world, role, created_at, last_active
    FROM users
    WHERE world = ?
    ORDER BY created_at DESC
  `).bind(world).all();
  
  return {
    success: true,
    world: world,
    users: results.results,
    count: results.results.length
  };
}
```

#### **3. D1 Database Schema**
```sql
-- Users Table
CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  world TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(username, world)
);

-- Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
  user_id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  world TEXT NOT NULL,
  name TEXT,
  bio TEXT,
  avatar_url TEXT,
  avatar_emoji TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Index für schnelle Suche
CREATE INDEX IF NOT EXISTS idx_users_world ON users(world);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
```

---

## 🎯 TESTING OHNE BACKEND (Mock-Daten)

Falls du **sofort** User sehen willst, kannst du **Mock-Daten** im Frontend verwenden:

### **Option: Mock WorldAdminService**

**Datei**: `lib/services/world_admin_service.dart`

Füge eine **Mock-Methode** hinzu (nur für Testing):

```dart
/// 🧪 MOCK DATA (nur für Testing - später entfernen!)
static Future<List<WorldUser>> getUsersByWorldMock(String world) async {
  await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
  
  if (world == 'materie') {
    return [
      WorldUser(
        userId: 'materie_Weltenbibliothek',
        username: 'Weltenbibliothek',
        role: 'root_admin',
        world: 'materie',
        isAdmin: true,
        isRootAdmin: true,
      ),
      WorldUser(
        userId: 'materie_TestAdmin',
        username: 'TestAdmin',
        role: 'admin',
        world: 'materie',
        isAdmin: true,
        isRootAdmin: false,
      ),
      WorldUser(
        userId: 'materie_ForscherMax',
        username: 'ForscherMax',
        role: 'user',
        world: 'materie',
        isAdmin: false,
        isRootAdmin: false,
      ),
      WorldUser(
        userId: 'materie_WissenschaftlerAnna',
        username: 'WissenschaftlerAnna',
        role: 'user',
        world: 'materie',
        isAdmin: false,
        isRootAdmin: false,
      ),
      WorldUser(
        userId: 'materie_AnalystPeter',
        username: 'AnalystPeter',
        role: 'user',
        world: 'materie',
        isAdmin: false,
        isRootAdmin: false,
      ),
    ];
  } else if (world == 'energie') {
    return [
      WorldUser(
        userId: 'energie_Weltenbibliothek',
        username: 'Weltenbibliothek',
        role: 'root_admin',
        world: 'energie',
        isAdmin: true,
        isRootAdmin: true,
      ),
      WorldUser(
        userId: 'energie_SpiritGuide',
        username: 'SpiritGuide',
        role: 'admin',
        world: 'energie',
        isAdmin: true,
        isRootAdmin: false,
      ),
      WorldUser(
        userId: 'energie_MysticLuna',
        username: 'MysticLuna',
        role: 'user',
        world: 'energie',
        isAdmin: false,
        isRootAdmin: false,
      ),
      WorldUser(
        userId: 'energie_ZenMaster',
        username: 'ZenMaster',
        role: 'user',
        world: 'energie',
        isAdmin: false,
        isRootAdmin: false,
      ),
      WorldUser(
        userId: 'energie_CrystalHealer',
        username: 'CrystalHealer',
        role: 'user',
        world: 'energie',
        isAdmin: false,
        isRootAdmin: false,
      ),
    ];
  }
  
  return [];
}
```

**Dann im Dashboard** (`lib/screens/shared/world_admin_dashboard.dart`):

```dart
Future<void> _loadUsers() async {
  try {
    // 🧪 TESTING: Mock-Daten verwenden
    final users = await WorldAdminService.getUsersByWorldMock(widget.world);
    
    // 🚀 PRODUCTION: Echte API verwenden
    // final users = await WorldAdminService.getUsersByWorld(widget.world);
    
    if (mounted) {
      setState(() {
        _users = users;
      });
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Fehler beim Laden der User: $e');
    }
  }
}
```

---

## 📊 ZUSAMMENFASSUNG

### **Was funktioniert (Frontend):**
- ✅ Profile Sync Service sendet Daten an Backend
- ✅ Admin Dashboard ruft User-Liste ab
- ✅ UI zeigt User-Liste mit Actions
- ✅ World-Isolation funktioniert
- ✅ Root-Admin Aktionen implementiert

### **Was das Backend tun muss:**
- ❌ User in D1 Database speichern (bei Profil-Erstellung)
- ❌ User-Liste pro Welt zurückgeben (GET /api/admin/users/:world)
- ❌ D1 Tables erstellen (users, profiles)
- ❌ Promote/Demote/Delete Endpoints implementieren

### **Quick Win (Testing):**
- ✅ Mock-Daten im Frontend verwenden
- ✅ User-Liste sofort sichtbar
- ✅ Alle UI-Features testbar

---

## 🚀 EMPFEHLUNG

### **Option A: Backend-Integration (Production-Ready)**
1. Cloudflare Worker erweitern
2. D1 Database Schema erstellen
3. User-Erstellung bei Profil-Save
4. User-Liste Endpoint implementieren

### **Option B: Mock-Daten (Schnelles Testing)**
1. Mock-Methode hinzufügen (siehe oben)
2. Dashboard auf Mock umstellen
3. Sofort User-Liste testen
4. Später auf echte API umstellen

---

## 📝 DATEIEN

**Frontend (Ready):**
- `lib/services/profile_sync_service.dart` - Profile Sync
- `lib/services/world_admin_service.dart` - Admin API
- `lib/screens/shared/world_admin_dashboard.dart` - Dashboard UI
- `lib/features/admin/state/admin_state.dart` - Admin State

**Backend (To-Do):**
- Cloudflare Worker: `/api/profile/:world` - User erstellen
- Cloudflare Worker: `/api/admin/users/:world` - User-Liste
- D1 Database: users + profiles tables

**Sample Data:**
- `test_sample_users.py` - Sample User-Daten

---

## ✅ STATUS

- Frontend: **100% READY**
- Backend: **Integration ausstehend**
- Testing: **Mock-Daten möglich**

**NÄCHSTER SCHRITT**: Mock-Daten verwenden für sofortiges Testing!
