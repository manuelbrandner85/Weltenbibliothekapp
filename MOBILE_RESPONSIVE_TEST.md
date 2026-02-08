# 📱 MOBILE-RESPONSIVE TEST-LEITFADEN

## ✅ TEST-URL:
https://5060-i6i6g94lpb9am6y5rb4gp-2e77fc33.sandbox.novita.ai

---

## 🧪 MOBILE TEST-SCHRITTE:

### **Schritt 1: Browser DevTools öffnen**
1. Chrome/Edge: `F12` oder `Ctrl+Shift+I`
2. Firefox: `F12` oder `Ctrl+Shift+M`
3. Safari: `Cmd+Option+I`

### **Schritt 2: Mobile-Ansicht aktivieren**
- Chrome: Click "Toggle device toolbar" Icon (📱)
- Wähle Gerät: **iPhone 12 Pro** oder **Samsung Galaxy S20**
- Viewport: **390x844** (iPhone) oder **360x800** (Android)

---

## 📋 MOBILE TEST-CHECKLISTE:

### ✅ **LAYOUT & NAVIGATION:**
- [ ] App lädt in < 3 Sekunden
- [ ] SafeArea verhindert Überlappung mit Notch/Status Bar
- [ ] Bottom Navigation Bar ist sichtbar & bedienbar
- [ ] AppBar mit Titel & Buttons gut lesbar
- [ ] Keine horizontalen Scrollbars (außer bei Polls)

### ✅ **CHAT INPUT:**
- [ ] Input-Feld ist vollständig sichtbar
- [ ] Tastatur-Popup überlagert nicht Input
- [ ] Send-Button ist groß genug für Touch (min. 44x44px)
- [ ] Avatar ist touch-freundlich
- [ ] Image-Upload-Button funktioniert
- [ ] @ Mentions Autocomplete erscheint über Tastatur

### ✅ **MESSAGE BUBBLES:**
- [ ] Message-Width max. 75% Bildschirmbreite
- [ ] Text ist lesbar (min. 14px Font-Size)
- [ ] Avatars sind sichtbar (24x24px)
- [ ] Long-Press für Edit/Delete funktioniert
- [ ] Reactions-Buttons sind groß genug für Touch

### ✅ **POLLS:**
- [ ] Poll-Container ist horizontal scrollbar
- [ ] Poll-Cards haben gute Touch-Targets
- [ ] Vote-Buttons sind groß genug (min. 48x48px)
- [ ] Ergebnisse sind lesbar
- [ ] Create-Poll-Dialog passt auf Screen

### ✅ **ROOM SELECTOR:**
- [ ] Room-Chips sind horizontal scrollbar
- [ ] Aktiver Room ist deutlich hervorgehoben
- [ ] Touch auf Room wechselt sofort
- [ ] Room-Namen sind vollständig lesbar

### ✅ **PINNED MESSAGES:**
- [ ] Banner oben ist sichtbar aber nicht störend
- [ ] Text ist lesbar
- [ ] Touch funktioniert
- [ ] Unpin-Button ist erreichbar

### ✅ **MENTIONS AUTOCOMPLETE:**
- [ ] Popup erscheint ÜBER Tastatur
- [ ] User-Liste ist scrollbar
- [ ] Touch-Selection funktioniert
- [ ] Schließt automatisch nach Auswahl

### ✅ **LANDSCAPE MODE:**
- [ ] App funktioniert im Querformat
- [ ] Layout passt sich an
- [ ] Keine Elemente abgeschnitten

### ✅ **PERFORMANCE:**
- [ ] Smooth Scrolling (60fps)
- [ ] Keine Lag bei Eingabe
- [ ] Auto-Refresh (5s) läuft flüssig
- [ ] Poll-Load verzögert nicht

---

## 🎨 ENERGIE-WELT SPEZIFISCH:

**Theme-Farben:**
- Primary: Purple `#9B51E0`
- Background: Dark `#0A0A0F`
- Cards: `#1A1A2E`

**Touch-Targets:**
- Min. 48x48dp (iOS: 44x44pt)
- Spacing: 8-12dp zwischen interaktiven Elementen

**Räume:**
- 🧘 Meditation
- 🌙 Astralreisen
- 💎 Chakra
- 💠 Kristalle
- 🎵 Frequenzen
- 💫 Traumarbeit

---

## 🎨 MATERIE-WELT SPEZIFISCH:

**Theme-Farben:**
- Primary: Red `#FF0000` / `#2196F3`
- Background: Dark `#1A1A1A`
- Cards: `#2A2A2A`

**Räume:**
- 🎭 Politik
- 🏛️ Geschichte
- 🛸 UFOs
- 👁️ Verschwörungen

---

## 🐛 BEKANNTE MOBILE-ISSUES (zu prüfen):

**Potenzielle Probleme:**
1. **Tastatur-Overlap:** iOS Tastatur könnte Input überlagern
2. **Mention-Popup:** Könnte unter Tastatur verschwinden
3. **Polls:** Horizontal-Scroll könnte mit Vertical-Scroll kollidieren
4. **Long-Press:** Könnte mit Scroll-Gesten kollidieren
5. **Avatar-Upload:** File-Picker könnte auf iOS fehlschlagen

---

## ✅ ERWARTETE MOBILE-OPTIMIERUNGEN:

**Bereits implementiert:**
- ✅ SafeArea Wrapping
- ✅ Responsive Width (75% für Messages)
- ✅ Touch-friendly Buttons
- ✅ Horizontal Scrolling für Polls
- ✅ FocusNode Management für Input
- ✅ Auto-Scroll nach unten bei neuen Messages

---

## 📊 MOBILE-TEST ERGEBNIS:

### **iPhone 12 Pro (390x844):**
- [ ] Layout ✅/❌
- [ ] Chat Input ✅/❌
- [ ] Mentions ✅/❌
- [ ] Polls ✅/❌
- [ ] Touch-Targets ✅/❌

### **Samsung Galaxy S20 (360x800):**
- [ ] Layout ✅/❌
- [ ] Chat Input ✅/❌
- [ ] Mentions ✅/❌
- [ ] Polls ✅/❌
- [ ] Touch-Targets ✅/❌

### **iPad (768x1024):**
- [ ] Layout ✅/❌
- [ ] Responsivität ✅/❌

---

## 🎯 EMPFOHLENE FIXES (falls Probleme gefunden):

1. **Input-Overlap:**
   ```dart
   // Verwende MediaQuery.of(context).viewInsets.bottom
   // für Tastatur-Höhe
   ```

2. **Mention-Popup Position:**
   ```dart
   // Positioniere relativ zu Input-Feld
   // Verwende Stack mit Positioned
   ```

3. **Touch-Targets vergrößern:**
   ```dart
   // Min. 48x48 für alle Buttons
   minimumSize: Size(48, 48)
   ```

---

**Test durchgeführt am:** [DATUM]
**Tester:** [NAME]
**Gerät:** [MODELL]
**Ergebnis:** ✅ PASS / ❌ FAIL / ⚠️ TEILWEISE
