# 🚀 RIVERPOD QUICK REFERENCE - WELTENBIBLIOTHEK

**Vollständige Implementierung aller Code-Beispiele aus deiner Anfrage**

---

## 📦 IMPORTS

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/state/admin_state.dart';
```

---

## 🎯 PATTERN 1: ADMIN-BUTTON (WORLD SCREENS)

### **Code:**
```dart
class MaterieWorldScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MaterieWorldScreen> createState() => _MaterieWorldScreenState();
}

class _MaterieWorldScreenState extends ConsumerState<MaterieWorldScreen> {
  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminStateProvider('materie'));
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (admin.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorldAdminDashboard(world: 'materie'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
```

### **Location:**
- `lib/screens/materie_world_screen.dart` (Zeile ~280)
- `lib/screens/energie_world_screen.dart` (Zeile ~280)

---

## 🔒 PATTERN 2: ZUGRIFFSKONTROLLE (DASHBOARD)

### **Code:**
```dart
class WorldAdminDashboard extends ConsumerStatefulWidget {
  final String world;
  const WorldAdminDashboard({required this.world, super.key});
  
  @override
  ConsumerState<WorldAdminDashboard> createState() => _WorldAdminDashboardState();
}

class _WorldAdminDashboardState extends ConsumerState<WorldAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminStateProvider(widget.world));
    
    if (!admin.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              Text('Kein Admin-Zugriff'),
              Text('Diese Seite ist nur für Admins zugänglich.'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      // Dashboard UI
    );
  }
}
```

### **Location:**
- `lib/screens/shared/world_admin_dashboard.dart` (Zeile ~340)

---

## 👥 PATTERN 3: USER-LISTE MIT ROLES

### **Code:**
```dart
Widget _buildUsersTab(AdminState admin) {
  return ListView.builder(
    itemCount: _users.length,
    itemBuilder: (context, index) {
      final user = _users[index];
      final isCurrentUser = user.username == admin.username;
      
      return ListTile(
        leading: user.role != 'user'
            ? const Icon(Icons.shield, color: Colors.amber)
            : const Icon(Icons.person),
        title: Row(
          children: [
            Text(user.username),
            if (isCurrentUser) ...[
              SizedBox(width: 8),
              Chip(label: Text('DU')),
            ],
          ],
        ),
        subtitle: Text(user.role),
        trailing: admin.isRootAdmin && !isCurrentUser
            ? PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'promote':
                      if (user.role == 'user') _promoteUser(user);
                      break;
                    case 'demote':
                      if (user.role == 'admin') _demoteUser(user);
                      break;
                    case 'delete':
                      _deleteUser(user);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (user.role == 'user')
                    PopupMenuItem(
                      value: 'promote',
                      child: Row([
                        Icon(Icons.arrow_upward, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Zum Admin machen'),
                      ]),
                    ),
                  if (user.role == 'admin' && !user.isRootAdmin)
                    PopupMenuItem(
                      value: 'demote',
                      child: Row([
                        Icon(Icons.arrow_downward, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Admin entfernen'),
                      ]),
                    ),
                  if (!user.isRootAdmin)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row([
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('User löschen'),
                      ]),
                    ),
                ],
              )
            : null,
      );
    },
  );
}
```

### **Location:**
- `lib/screens/shared/world_admin_dashboard.dart` (Zeile ~395)

---

## ⬆️ PATTERN 4: PROMOTE USER

### **Code:**
```dart
Future<void> _promoteUser(WorldUser user) async {
  final admin = ref.read(adminStateProvider(widget.world));
  
  if (!admin.isRootAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Nur Root-Admins können User befördern.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  if (user.isRootAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Root-Admins können nicht befördert werden.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('User zu Admin befördern?'),
      content: Text('Möchtest du ${user.username} zu Admin befördern?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Befördern'),
        ),
      ],
    ),
  );
  
  if (confirm != true) return;
  
  final success = await WorldAdminService.promoteUser(widget.world, user.userId);
  
  if (mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${user.username} wurde zu Admin befördert'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUsers(); // Refresh
    }
  }
}
```

### **Location:**
- `lib/screens/shared/world_admin_dashboard.dart` (Zeile ~160)

---

## ⬇️ PATTERN 5: DEMOTE ADMIN

### **Code:**
```dart
Future<void> _demoteUser(WorldUser user) async {
  final admin = ref.read(adminStateProvider(widget.world));
  
  if (!admin.isRootAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Nur Root-Admins können Admins degradieren.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  if (user.isRootAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Root-Admins können nicht degradiert werden.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  if (user.username == admin.username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Du kannst dich nicht selbst degradieren.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Admin-Rechte entfernen?'),
      content: Text('Möchtest du ${user.username} zum normalen User machen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Degradieren'),
        ),
      ],
    ),
  );
  
  if (confirm != true) return;
  
  final success = await WorldAdminService.demoteUser(widget.world, user.userId);
  
  if (mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${user.username} wurde zu User degradiert'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUsers(); // Refresh
    }
  }
}
```

### **Location:**
- `lib/screens/shared/world_admin_dashboard.dart` (Zeile ~215)

---

## 🗑️ PATTERN 6: DELETE USER

### **Code:**
```dart
Future<void> _deleteUser(WorldUser user) async {
  final admin = ref.read(adminStateProvider(widget.world));
  
  if (!admin.isRootAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Nur Root-Admins können User löschen.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  if (user.username == admin.username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Du kannst dich nicht selbst löschen.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('⚠️ User löschen?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Möchtest du ${user.username} wirklich löschen?'),
          SizedBox(height: 8),
          Text(
            '⚠️ Diese Aktion kann nicht rückgängig gemacht werden!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Löschen'),
        ),
      ],
    ),
  );
  
  if (confirm != true) return;
  
  final success = await WorldAdminService.deleteUser(widget.world, user.userId);
  
  if (mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${user.username} wurde gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUsers(); // Refresh
    }
  }
}
```

### **Location:**
- `lib/screens/shared/world_admin_dashboard.dart` (Zeile ~270)

---

## 🔄 PATTERN 7: REFRESH ADMIN-STATUS

### **Code:**
```dart
// Nach Profil-Speichern
await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileSettingsScreen(),
  ),
);

// 🔥 WICHTIG: Admin-Status neu laden
if (mounted) {
  ref.read(adminStateProvider('materie').notifier).refresh();
}
```

### **Location:**
- `lib/screens/materie_world_screen.dart` (Zeile ~310)
- `lib/screens/energie_world_screen.dart` (Zeile ~310)

### **Dashboard Refresh-Button:**
```dart
IconButton(
  icon: const Icon(Icons.refresh),
  onPressed: () {
    ref.read(adminStateProvider(widget.world).notifier).refresh();
    _loadDashboardData();
  },
  tooltip: 'Aktualisieren',
),
```

### **Location:**
- `lib/screens/shared/world_admin_dashboard.dart` (Zeile ~355)

---

## 🎓 ADVANCED PATTERNS

### **Pattern: Admin-Status prüfen (read vs watch)**
```dart
// WATCH: UI updated automatisch
final admin = ref.watch(adminStateProvider('materie'));
if (admin.isAdmin) { /* ... */ }

// READ: Einmaliger Zugriff (z.B. in Funktionen)
final admin = ref.read(adminStateProvider('materie'));
if (!admin.isRootAdmin) { /* ... */ }
```

### **Pattern: Backend-Verifizierung prüfen**
```dart
final admin = ref.watch(adminStateProvider('materie'));

if (admin.backendVerified) {
  // Backend hat bestätigt
  print('Admin-Status vom Backend verifiziert');
} else {
  // Nur lokaler State (Offline-Modus)
  print('Admin-Status aus lokalem Storage');
}
```

### **Pattern: Debug-Informationen**
```dart
final admin = ref.watch(adminStateProvider('materie'));

print('Username: ${admin.username}');
print('Role: ${admin.role}');
print('isAdmin: ${admin.isAdmin}');
print('isRootAdmin: ${admin.isRootAdmin}');
print('World: ${admin.world}');
print('Backend Verified: ${admin.backendVerified}');
```

---

## 🌐 DEPLOYMENT

### **Web-Version:**
```
https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai
```

### **Test-Account:**
- **Username:** `Weltenbibliothek`
- **Password:** `Jolene2305`

---

## 📚 WEITERE RESSOURCEN

- `VERSION_11_FINAL_SUMMARY.md` - Vollständige Feature-Übersicht
- `RIVERPOD_MIGRATION_GUIDE.md` - Migration-Anleitung
- `lib/features/admin/state/admin_state.dart` - State Management Code
- `lib/core/constants/roles.dart` - Rollen-System

---

**VERSION:** 11 FINAL  
**ALLE CODE-BEISPIELE:** ✅ IMPLEMENTIERT  
**STATUS:** ✅ PRODUKTIONSREIF
