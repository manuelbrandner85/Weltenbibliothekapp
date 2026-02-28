# 🦞 OpenClaw AI Integration - Setup-Anleitung

## 📋 Übersicht

Deine Weltenbibliothek-App ist jetzt mit **OpenClaw AI** integriert! OpenClaw läuft auf deinem **Hostinger VPS** und stellt AI-Features für die App bereit.

---

## ✅ Was wurde integriert?

### **AI-Features die über OpenClaw laufen:**

1. **🔍 Recherche-Tool**
   - Multi-Source Aggregation
   - Automatische Zusammenfassungen
   - Telegram-Kanal-Monitoring

2. **🛡️ Propaganda-Detektor**
   - Textanalyse auf Manipulationstechniken
   - Objektivitäts-Score
   - Empfehlungen

3. **🔮 Traum-Analyse**
   - Symbolische Interpretation
   - Spirituelle Bedeutungen
   - Chakra-Verbindungen

4. **💎 Chakra-Empfehlungen**
   - Personalisierte Heilstein-Empfehlungen
   - Solfeggio-Frequenzen
   - Yoga-Übungen & Meditationen

5. **🧘 Meditation-Generator**
   - Custom Meditationsskripte
   - Personalisiert nach Intention
   - Mit Visualisierungen

6. **💬 Chat-Enhancement**
   - Smart Reply Suggestions
   - Kontext-bewusste Antworten

---

## 🚀 Setup auf Hostinger VPS

### **Schritt 1: SSH-Verbindung zu Hostinger VPS**

```bash
ssh root@deine-vps-ip
# Oder mit SSH-Key:
ssh -i ~/.ssh/id_rsa root@deine-vps-ip
```

### **Schritt 2: OpenClaw installieren**

```bash
# Installer herunterladen und ausführen
curl -fsSL https://openclaw.ai/install.sh | bash

# Nach Installation:
openclaw --version
# Sollte zeigen: openclaw v1.x.x
```

### **Schritt 3: OpenClaw konfigurieren**

```bash
# Onboarding starten
openclaw onboard

# Folge den Schritten:
# 1. Wähle AI-Model: Claude 3.5 Sonnet (empfohlen)
# 2. API-Key eingeben: Dein Claude/GPT API-Key
# 3. Gateway Port: 3000 (Standard)
# 4. Messenger verbinden: Optional (für direkte Interaktion)
```

### **Schritt 4: Gateway Token generieren**

```bash
# API-Key für Flutter App generieren
openclaw get-api-key

# Ausgabe z.B.:
# Gateway Token: claw_sk_abc123xyz...
```

**📝 WICHTIG:** Kopiere diesen Token! Du brauchst ihn für die Flutter App.

### **Schritt 5: OpenClaw als Service einrichten**

```bash
# Systemd Service erstellen
sudo nano /etc/systemd/system/openclaw.service
```

Füge ein:
```ini
[Unit]
Description=OpenClaw AI Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw
ExecStart=/usr/local/bin/openclaw start --port 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Service starten:
```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
sudo systemctl status openclaw
```

### **Schritt 6: Firewall konfigurieren**

```bash
# Port 3000 öffnen (oder deinen gewählten Port)
sudo ufw allow 3000/tcp
sudo ufw reload
```

### **Schritt 7: Nginx Reverse Proxy (Optional, aber empfohlen)**

```bash
# Nginx installieren (falls nicht vorhanden)
sudo apt install nginx

# Nginx-Config erstellen
sudo nano /etc/nginx/sites-available/openclaw
```

Füge ein:
```nginx
server {
    listen 80;
    server_name openclaw.deine-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Aktivieren:
```bash
sudo ln -s /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### **Schritt 8: SSL-Zertifikat mit Let's Encrypt (Optional)**

```bash
# Certbot installieren
sudo apt install certbot python3-certbot-nginx

# Zertifikat erstellen
sudo certbot --nginx -d openclaw.deine-domain.com
```

---

## 📱 Flutter App konfigurieren

### **Schritt 1: API-Config bearbeiten**

Öffne: `lib/config/api_config.dart`

Ersetze:
```dart
static const String openClawGatewayUrl = 'http://localhost:3000';
```

Mit deiner URL:
```dart
// Mit Domain + SSL (empfohlen):
static const String openClawGatewayUrl = 'https://openclaw.deine-domain.com';

// ODER mit direkter IP:
static const String openClawGatewayUrl = 'http://123.456.789.10:3000';
```

### **Schritt 2: Gateway Token eintragen**

Ersetze:
```dart
static const String openClawGatewayToken = 'YOUR_OPENCLAW_GATEWAY_TOKEN_HERE';
```

Mit deinem Token:
```dart
static const String openClawGatewayToken = 'claw_sk_abc123xyz...';
```

### **Schritt 3: App neu bauen**

```bash
cd /home/user/flutter_app
flutter pub get
flutter build web --release
```

---

## 🧪 Testen

### **Test 1: OpenClaw Health Check**

```bash
# Auf VPS:
curl http://localhost:3000/health

# Sollte antworten:
# {"status":"ok","version":"1.x.x"}
```

### **Test 2: API-Request testen**

```bash
curl -X POST http://localhost:3000/api/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dein_gateway_token" \
  -d '{
    "model": "claude-3-5-sonnet",
    "prompt": "Hallo OpenClaw!",
    "max_tokens": 100
  }'
```

### **Test 3: In Flutter App testen**

In der App:
1. Öffne Recherche-Tool
2. Suche nach einem Thema
3. OpenClaw sollte automatisch verwendet werden
4. Bei Fehler fällt App auf Cloudflare zurück

---

## 🔍 Debugging

### **Logs anschauen:**

```bash
# OpenClaw Logs
sudo journalctl -u openclaw -f

# Nginx Logs (falls Reverse Proxy)
sudo tail -f /var/log/nginx/error.log
```

### **Status prüfen:**

```bash
# OpenClaw Service
sudo systemctl status openclaw

# Ist Port 3000 offen?
sudo netstat -tulpn | grep 3000
```

### **Häufige Probleme:**

**Problem:** "Connection refused"
- **Lösung:** Prüfe ob OpenClaw läuft: `sudo systemctl status openclaw`

**Problem:** "Gateway Token ungültig"
- **Lösung:** Neuen Token generieren: `openclaw get-api-key`

**Problem:** "502 Bad Gateway" (bei Nginx)
- **Lösung:** Prüfe ob OpenClaw läuft und auf Port 3000 hört

---

## 📊 Monitoring

### **System Status in App anzeigen:**

In deiner Flutter App kannst du den Status abrufen:

```dart
final aiManager = AIServiceManager();
final status = await aiManager.getSystemStatus();
print(status);
```

Ausgabe:
```json
{
  "openclaw": {
    "available": true,
    "url": "https://openclaw.deine-domain.com",
    "status": {"version": "1.x.x", "uptime": "24h"}
  },
  "cloudflare": {
    "available": true,
    "url": "https://weltenbibliothek-api-v2.brandy13062.workers.dev"
  },
  "active_service": "openclaw"
}
```

---

## 💰 Kosten

### **Hostinger VPS:**
- VPS KVM 1: ~4€/Monat (2 GB RAM, 1 CPU)
- VPS KVM 2: ~8€/Monat (4 GB RAM, 2 CPU) ← Empfohlen

### **OpenClaw:**
- Software: **Kostenlos** (Open Source)
- Claude API: ~$5-20/Monat (je nach Nutzung)
- GPT-4 API: ~$10-30/Monat (je nach Nutzung)

**Gesamt:** ~15-40€/Monat (VPS + API-Nutzung)

---

## 🎯 Nächste Schritte

1. ✅ **OpenClaw installieren** auf Hostinger VPS
2. ✅ **Gateway Token** in Flutter App eintragen
3. ✅ **App neu bauen** und testen
4. ✅ **Features nutzen** (Recherche, Traum-Analyse, etc.)

---

## 📚 Weitere Infos

- **OpenClaw Docs:** https://openclaw.ai/docs
- **GitHub:** https://github.com/OpenClaw/openclaw
- **Discord Community:** https://discord.gg/openclaw

---

## ✨ Das war's!

Deine Weltenbibliothek nutzt jetzt:
- 🦞 **OpenClaw AI** (Hostinger VPS) - Primär
- ☁️ **Cloudflare AI** - Automatischer Fallback

**Viel Erfolg!** 🚀
