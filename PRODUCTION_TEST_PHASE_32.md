# Production Test Plan - Phase 32

**Datum**: 8. Februar 2026  
**Phase**: 32 - Admin System Erweiterung  
**Status**: Bereit für Testing  

---

## 🎯 Test-Ziele

1. **Admin-Account Validierung**: Beide Admin-Accounts funktionieren
2. **Passwort-Prüfung**: Korrekte Passwort-Validierung
3. **Rollen-System**: Berechtigungen korrekt zugewiesen
4. **User-Liste**: Admin-Dashboard zeigt User korrekt an

---

## 🧪 Test-Suite

### TEST 1: Root-Admin Login (Weltenbibliothek)
**URL**: https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai

**Schritte**:
1. Profil-Editor öffnen (Energie oder Materie Welt)
2. Username eingeben: `Weltenbibliothek`
3. Passwortfeld sollte automatisch erscheinen mit:
   - 👑 Root-Admin Zugriff
   - Amber-Styling
4. Passwort eingeben: `Jolene2305`
5. Profil speichern

**Erwartetes Ergebnis**:
```json
{
  "success": true,
  "username": "Weltenbibliothek",
  "role": "root_admin",
  "is_admin": true,
  "is_root_admin": true
}
```

**Berechtigungen**:
- ✅ User-Verwaltung (erstellen, löschen, befördern)
- ✅ Content-Management (Tabs, Tools, Marker)
- ✅ Admin-Dashboard Vollzugriff
- ✅ System-Administration

---

### TEST 2: Content-Editor Login (Weltenbibliothekedit)
**URL**: https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai

**Schritte**:
1. Profil-Editor öffnen (Energie oder Materie Welt)
2. Username eingeben: `Weltenbibliothekedit`
3. Passwortfeld sollte automatisch erscheinen mit:
   - ✏️ Content-Editor Zugriff
   - Amber-Styling
4. Passwort eingeben: `Jolene2305`
5. Profil speichern

**Erwartetes Ergebnis**:
```json
{
  "success": true,
  "username": "Weltenbibliothekedit",
  "role": "content_editor",
  "is_admin": true,
  "is_root_admin": false
}
```

**Berechtigungen**:
- ✅ Content-Management (Tabs, Tools, Marker)
- ✅ Medien-Upload
- ✅ Publish-Rechte
- ❌ User-Verwaltung (KEIN Zugriff)
- ❌ System-Administration (KEIN Zugriff)

---

### TEST 3: Falsches Passwort (Negativtest)
**URL**: https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai

**Schritte**:
1. Profil-Editor öffnen
2. Username: `Weltenbibliothekedit`
3. Passwort: `WrongPassword123` (falsch)
4. Profil speichern

**Erwartetes Ergebnis**:
```json
{
  "success": false,
  "error": "Invalid content editor password"
}
```

**UI-Feedback**:
- ❌ Fehlermeldung angezeigt
- 🔴 "Ungültiges Passwort" oder ähnlich

---

### TEST 4: Admin-Dashboard User-Liste
**URL**: https://5060-ingyb9x7032nc991qsp0l-0e616f0a.sandbox.novita.ai

**Schritte**:
1. Als Root-Admin einloggen (Weltenbibliothek)
2. Admin-Dashboard öffnen
3. "Users" Tab öffnen

**Erwartetes Ergebnis**:
- ✅ User-Liste wird angezeigt
- ✅ Enthält: Weltenbibliothek, Weltenbibliothekedit, weitere User
- ✅ Rollen korrekt angezeigt (root_admin, content_editor, user)

**Als Content-Editor**:
1. Als Content-Editor einloggen (Weltenbibliothekedit)
2. Admin-Dashboard öffnen
3. "Users" Tab öffnen

**Erwartetes Ergebnis**:
- ❌ User-Liste NICHT sichtbar (keine Berechtigung)
- ℹ️ "Keine Berechtigung" Meldung

---

### TEST 5: Backend API Direkttest
**Backend URL**: https://weltenbibliothek-api-v2.brandy13062.workers.dev

**Test 5.1: Root-Admin Profil erstellen**
```bash
curl -X POST \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/profile/materie \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token-123" \
  -H "X-World: materie" \
  -H "X-Role: user" \
  -d '{
    "username": "Weltenbibliothek",
    "name": "Root Admin",
    "bio": "System Administrator",
    "avatarEmoji": "👑",
    "password": "Jolene2305"
  }'
```

**Erwartetes Ergebnis**:
```json
{
  "success": true,
  "username": "Weltenbibliothek",
  "user_id": "root_admin_001",
  "role": "root_admin",
  "is_admin": true,
  "is_root_admin": true,
  "d1_saved": true
}
```

---

**Test 5.2: Content-Editor Profil erstellen**
```bash
curl -X POST \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/profile/materie \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token-123" \
  -H "X-World: materie" \
  -H "X-Role: user" \
  -d '{
    "username": "Weltenbibliothekedit",
    "name": "Content Editor",
    "bio": "Zuständig für Content-Management",
    "avatarEmoji": "✏️",
    "password": "Jolene2305"
  }'
```

**Erwartetes Ergebnis**:
```json
{
  "success": true,
  "username": "Weltenbibliothekedit",
  "user_id": "materie_Weltenbibliothekedit",
  "role": "content_editor",
  "is_admin": true,
  "is_root_admin": false
}
```

---

**Test 5.3: Falsches Passwort**
```bash
curl -X POST \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/profile/materie \
  -H "Content-Type: application/json" \
  -d '{
    "username": "Weltenbibliothekedit",
    "password": "WrongPassword"
  }'
```

**Erwartetes Ergebnis**:
```json
{
  "success": false,
  "error": "Invalid content editor password"
}
```

---

## 📊 Test-Matrix

| Test | Status | Bemerkungen |
|------|--------|-------------|
| TEST 1: Root-Admin Login | ⏳ Ausstehend | Weltenbibliothek + Jolene2305 |
| TEST 2: Content-Editor Login | ⏳ Ausstehend | Weltenbibliothekedit + Jolene2305 |
| TEST 3: Falsches Passwort | ⏳ Ausstehend | Negativtest |
| TEST 4: Admin-Dashboard | ⏳ Ausstehend | User-Liste Sichtbarkeit |
| TEST 5.1: Backend Root-Admin | ✅ BESTANDEN | API-Test durchgeführt |
| TEST 5.2: Backend Content-Editor | ✅ BESTANDEN | API-Test durchgeführt |
| TEST 5.3: Backend Falsches PW | ✅ BESTANDEN | API-Test durchgeführt |

---

## 🐛 Bekannte Issues

### Issue 1: Admin-Dashboard zeigt keine User (UNBESTÄTIGT)
**Status**: Zu prüfen  
**Beschreibung**: User berichtet, dass Admin-Dashboard keine User anzeigt  
**Mögliche Ursachen**:
1. AdminState nutzt alte/gecachte Daten
2. Backend-Response enthält `role` aber AdminState erwartet `isRootAdmin`
3. Riverpod State nicht aktualisiert nach Backend-Update

**Debugging-Schritte**:
1. Browser-Console öffnen
2. Als Root-Admin einloggen
3. Admin-Dashboard öffnen
4. Console-Logs prüfen:
   - "DASHBOARD ADMIN-CHECK"
   - "Admin isRootAdmin: ..."
   - "Loading users for world: ..."

---

## ✅ Production Readiness Checklist

### Backend
- [x] Backend deployed (v12.0.0)
- [x] Passwort-Validierung funktioniert
- [x] Beide Admin-Accounts validiert
- [x] KV-Bindings konfiguriert
- [x] API-Tests bestanden (3/3)

### Flutter App
- [x] Code committed (Commit 7bc9537)
- [x] Flutter Analyze bestanden (0 ERRORS)
- [x] Build erfolgreich (Web)
- [x] Server läuft (Port 5060)
- [ ] UI-Tests durchgeführt (0/4)
- [ ] Integration-Tests durchgeführt

### Sicherheit
- [x] Passwort-Validierung serverseitig
- [x] Role-Based Access Control (RBAC)
- [ ] Passwörter aus Hard-Code entfernen (TODO)
- [ ] Secure Storage für Credentials

---

## 🚀 Nächste Schritte

### Priorität 1: UI Testing
1. Öffne Preview URL
2. Führe TEST 1-4 durch
3. Dokumentiere Ergebnisse
4. Behebe Issues falls gefunden

### Priorität 2: Integration Testing
1. Teste Workflows:
   - Admin erstellt User
   - Content-Editor bearbeitet Content
   - Normale User haben keinen Admin-Zugriff
2. Prüfe Permissions:
   - Root-Admin sieht alles
   - Content-Editor sieht nur Content-Management
   - Normale User sehen keine Admin-Features

### Priorität 3: Production Deployment
1. Finale Review
2. Backup erstellen
3. Git Tag für Phase 32
4. Production Release

---

**Erstellt**: 8. Februar 2026  
**Für**: Manuel Brandner  
**Projekt**: Weltenbibliothek  
**Phase**: 32 - Admin System Erweiterung  
