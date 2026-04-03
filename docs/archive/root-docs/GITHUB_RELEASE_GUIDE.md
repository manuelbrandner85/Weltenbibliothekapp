# 📦 GitHub Release v5.7.0 - Upload Anleitung

## 🎯 Ziel: APK-Dateien auf GitHub verfügbar machen

Da APK-Dateien (je 116 MB) GitHubs 100 MB Datei-Limit überschreiten, nutzen wir **GitHub Releases** für die Distribution.

---

## 📋 **Schritt-für-Schritt Anleitung**

### **1. GitHub Releases öffnen**
🔗 https://github.com/manuelbrandner85/Weltenbibliothekapp/releases

Oder navigiere:
```
Repository → Rechte Seite → "Releases" → "Draft a new release"
```

---

### **2. Release erstellen**

#### **Tag Version**
```
v5.7.0
```
✅ Klicke auf "Create new tag: v5.7.0 on publish"

#### **Release Title**
```
Weltenbibliothek v5.7.0 - Production Ready 🎉
```

#### **Description** (kopiere diesen Text):

```markdown
# 🎊 Weltenbibliothek v5.7.0 - Production Ready

## ✅ Highlights

### Kritische Fixes
- ✅ **Voice-Chat komplett überarbeitet**
  - TelegramVoiceScreen → ModernVoiceChatScreen Migration
  - 2×5 Grid für bis zu 10 Teilnehmer
  - WebRTC Provider vollständig funktional
  - Active-Speaker Highlighting
  - Mute/Unmute, Leave und Reconnection Handling

### Code-Qualität: 551 → 0 Fehler (-100%)
- **Phase 1-2:** 551 → 40 Fehler (-93%)
- **Voice-Chat Fix:** 40 → 22 Fehler (-96%)
- **Final Cleanup:** 22 → 0 Fehler (-100%)

---

## 📥 Downloads

### 🆕 **Fresh Build (EMPFOHLEN)**
**Datei:** `weltenbibliothek-v5.7.0-fresh.apk`
- **Größe:** 116 MB
- **Quelle:** GitHub Clone (neuester Code-Stand)
- **Build-Zeit:** 337.3s
- **Status:** ✅ Production-Ready

### 📦 **Original Build**
**Datei:** `weltenbibliothek-v5.7.0-original.apk`
- **Größe:** 116 MB
- **Quelle:** Sandbox Build
- **Build-Zeit:** 266.1s
- **Status:** ✅ Production-Ready

---

## 📲 Installation

### Android 8+ erforderlich

1. **APK herunterladen**
   - Empfohlen: Fresh Build

2. **Unbekannte Quellen aktivieren**
   ```
   Einstellungen → Sicherheit → Unbekannte Quellen → An
   ```

3. **APK installieren**
   - Datei öffnen und Installation bestätigen

4. **Berechtigungen erteilen**
   - ✅ Mikrofon (für Voice-Chat)
   - ✅ Internet (für Live-Features)
   - ✅ Storage (für Offline-Daten)

---

## ✨ Features

- 🔍 **KI-Recherche** - Intelligente Wissenssuche
- 💬 **Live-Chat** - 6 thematische Räume
- 🎙️ **Voice-Chat** - WebRTC, bis 10 Teilnehmer
- 📊 **Analysis Tools** - PDF, Audio, Video
- 🌍 **Energy-World** - Energie-Visualisierung
- 📴 **Offline-Support** - PWA mit Service Worker

---

## 🔧 Technische Details

```yaml
Version:         5.7.0
Flutter SDK:     3.35.4
Dart SDK:        3.9.2
Target SDK:      Android 36
Min SDK:         Android 8 (API 26)
Build Type:      Release
Code-Qualität:   100/100 (0 Fehler)
Bundle-Größe:    116 MB (optimiert)
```

---

## 🌐 Live-Deployments

- **Cloudflare Pages:** https://aafd03fa.weltenbibliothek-ey9.pages.dev
- **GitHub Repo:** https://github.com/manuelbrandner85/Weltenbibliothekapp

---

## 📖 Dokumentation

- [CHANGELOG.md](CHANGELOG.md) - Vollständige Versionshistorie
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - 25+ Test Cases
- [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md) - Optimierungs-Roadmap
- [Release Notes](releases/v5.7.0/README.md) - Detaillierte Release-Infos

---

## 🐛 Known Issues

**Keine kritischen Bugs bekannt!** 🎉

Issues melden: https://github.com/manuelbrandner85/Weltenbibliothekapp/issues

---

**Made with ❤️ für Android 8+**
```

---

### **3. APK-Dateien hochladen**

#### **Lokale Dateien:**
```
releases/v5.7.0/weltenbibliothek-v5.7.0-fresh.apk (116 MB)
releases/v5.7.0/weltenbibliothek-v5.7.0-original.apk (116 MB)
```

#### **Alternative: Von HTTP Server downloaden**
Wenn du die Dateien lokal nicht hast:
🔗 https://8080-idoifhv2zpl26bvr93n22-de59bda9.sandbox.novita.ai

1. Lade beide APKs herunter
2. Benenne sie um:
   - `app-release-fresh.apk` → `weltenbibliothek-v5.7.0-fresh.apk`
   - `app-release.apk` → `weltenbibliothek-v5.7.0-original.apk`

#### **Upload auf GitHub:**
1. Im Release-Editor unten: "Attach binaries"
2. Ziehe beide APK-Dateien hinein
3. Warte bis Upload abgeschlossen (je ~2-3 Minuten pro Datei)

---

### **4. Release veröffentlichen**

✅ Klicke auf **"Publish release"**

---

## ✅ **Nach der Veröffentlichung**

### **Download-URLs werden sein:**

```
https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.7.0/weltenbibliothek-v5.7.0-fresh.apk

https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.7.0/weltenbibliothek-v5.7.0-original.apk
```

### **Release-Seite:**
```
https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.7.0
```

---

## 🔄 **Update: Release Notes in README**

Aktualisiere die README.md mit Download-Links:

```markdown
## 📥 Downloads

**Latest Release:** [v5.7.0](https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/tag/v5.7.0)

### APK-Downloads:
- [Fresh Build (116 MB)](https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.7.0/weltenbibliothek-v5.7.0-fresh.apk) - **EMPFOHLEN**
- [Original Build (116 MB)](https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/download/v5.7.0/weltenbibliothek-v5.7.0-original.apk)
```

---

## 📊 **Zusammenfassung**

```
✅ GitHub Repository:   Vollständig synchronisiert
✅ Code & Docs:         Gepusht (Commit a5e2157)
✅ APK-Dateien:         Bereit zum Upload (je 116 MB)
⏳ GitHub Release:      Manuell erstellen (siehe Anleitung oben)

Nächster Schritt:
→ GitHub Releases öffnen
→ v5.7.0 Release erstellen
→ Beide APKs hochladen
→ Release veröffentlichen
```

---

## 🎯 **Warum GitHub Releases?**

✅ **Vorteile:**
- Keine 100 MB File-Size-Limits
- Dedizierte Download-URLs
- Versionshistorie
- Release Notes Integration
- Automatische Benachrichtigungen

❌ **Nicht möglich:**
- APKs direkt im Git-Repository (zu groß)
- Git LFS (nicht installiert/konfiguriert)

---

**Viel Erfolg beim Release! 🚀**
