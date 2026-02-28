# 🦞 OpenClaw Integration - Quick Start

## ✅ Gateway Token konfiguriert!

Dein OpenClaw Gateway Token ist jetzt in der App eingetragen:
```
Token: lHNu7aoMko3O3ptFgBA1POK71xTf8YHw
```

---

## 🚀 Nächste Schritte

### **Schritt 1: OpenClaw URL eintragen** (wenn bereit)

Sobald OpenClaw auf deinem Hostinger VPS läuft, musst du nur noch die URL ändern:

📄 **Datei:** `lib/config/api_config.dart`

**Aktuelle Zeile:**
```dart
static const String openClawGatewayUrl = 'http://localhost:3000';
```

**Ersetzen mit deiner VPS URL:**
```dart
// Option A: Mit Domain (empfohlen wenn du SSL hast)
static const String openClawGatewayUrl = 'https://openclaw.deine-domain.com';

// Option B: Direkte IP-Adresse
static const String openClawGatewayUrl = 'http://DEINE_VPS_IP:3000';
```

**Beispiele:**
```dart
// Hostinger VPS mit Domain:
static const String openClawGatewayUrl = 'https://openclaw.weltenbibliothek.com';

// Hostinger VPS mit IP (z.B. 185.23.45.67):
static const String openClawGatewayUrl = 'http://185.23.45.67:3000';
```

---

### **Schritt 2: App neu bauen**

```bash
cd /home/user/flutter_app
flutter pub get
flutter build web --release
```

---

## 🧪 Testen

### **Test 1: Gateway Status prüfen**

Wenn OpenClaw auf deinem Hostinger VPS läuft, teste die Verbindung:

```bash
# Von deinem lokalen Computer aus:
curl -X GET http://DEINE_VPS_IP:3000/health \
  -H "Authorization: Bearer lHNu7aoMko3O3ptFgBA1POK71xTf8YHw"

# Erwartete Antwort:
# {"status":"ok","version":"1.x.x"}
```

### **Test 2: AI-Request testen**

```bash
curl -X POST http://DEINE_VPS_IP:3000/api/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer lHNu7aoMko3O3ptFgBA1POK71xTf8YHw" \
  -d '{
    "model": "claude-3-5-sonnet",
    "prompt": "Hallo von Weltenbibliothek!",
    "max_tokens": 100
  }'
```

---

## 🔧 OpenClaw auf Hostinger installieren

Falls du OpenClaw noch nicht auf deinem Hostinger VPS installiert hast:

### **1. SSH-Verbindung:**
```bash
ssh root@DEINE_VPS_IP
```

### **2. OpenClaw installieren:**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

### **3. OpenClaw starten:**
```bash
openclaw onboard
# Folge den Schritten im Setup-Wizard
```

### **4. Als Service einrichten:**
```bash
# Siehe OPENCLAW_SETUP.md für detaillierte Anleitung
sudo systemctl enable openclaw
sudo systemctl start openclaw
```

### **5. Port 3000 in Firewall öffnen:**
```bash
sudo ufw allow 3000/tcp
sudo ufw reload
```

---

## 📊 App-Funktionalität

### **Aktueller Status:**

| Komponente | Status | Bemerkung |
|------------|--------|-----------|
| **Gateway Token** | ✅ Eingetragen | `lHNu7a...8YHw` |
| **Gateway URL** | ⚠️ localhost | Muss auf VPS-URL geändert werden |
| **OpenClaw VPS** | ❓ Unbekannt | Läuft OpenClaw auf Hostinger? |
| **Fallback (Cloudflare)** | ✅ Aktiv | App funktioniert bereits! |

### **App funktioniert JETZT schon!**

Die App nutzt automatisch Cloudflare als Fallback, solange OpenClaw nicht erreichbar ist.

Sobald du die OpenClaw URL einträgst und OpenClaw läuft, switcht die App automatisch zu OpenClaw!

---

## 🎯 Features mit OpenClaw

Wenn OpenClaw läuft, werden diese Features erweitert:

| Feature | Ohne OpenClaw | Mit OpenClaw |
|---------|---------------|--------------|
| **Recherche** | ✅ Basic | ✅ AI-Enhanced |
| **Propaganda-Detektor** | ⚠️ Basis | ✅ Detailliert |
| **Traum-Analyse** | ⚠️ Template | ✅ AI-Generiert |
| **Chakra-Tipps** | ✅ Standard | ✅ Personalisiert |
| **Meditation** | ✅ Template | ✅ Custom AI |
| **Chat Smart Replies** | ❌ Keine | ✅ AI-Powered |

---

## 🚀 Was ist dein nächster Schritt?

**Option A: OpenClaw jetzt auf Hostinger einrichten**
- SSH zu Hostinger VPS
- OpenClaw installieren (siehe OPENCLAW_SETUP.md)
- URL in App eintragen
- App neu bauen
- Fertig! 🎉

**Option B: Erstmal testen ohne OpenClaw**
- App läuft bereits mit Cloudflare
- Teste alle Features
- OpenClaw später hinzufügen

---

## 📚 Dokumentation

**Ausführliche Anleitung:**
📄 `OPENCLAW_SETUP.md` - Komplette Hostinger VPS Setup-Anleitung

**OpenClaw Docs:**
🌐 https://openclaw.ai/docs

---

## ❓ Brauchst du Hilfe?

Sage mir einfach:
- "Hilf mir mit Hostinger Setup" - Ich führe dich durch
- "OpenClaw ist installiert" - Ich helfe mit URL-Config
- "Starte die App neu" - Ich baue die App mit neuer Config

---

**Dein Gateway Token ist sicher gespeichert!** 🔐
Token: `lHNu7aoMko3O3ptFgBA1POK71xTf8YHw`
