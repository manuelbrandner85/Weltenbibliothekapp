# ☁️ SoundCloud Integration - Weltenbibliothek

## 🎵 Übersicht

Die App integriert jetzt **SoundCloud** als Musik-Quelle neben Radio Browser:
- ✅ **SoundCloud Player Widget** - WebView-basierte Embed-Integration
- ✅ **Kuratierte Playlists** - 5 Genre-basierte SoundCloud Sets
- ✅ **Custom URL Support** - Benutzer können eigene SoundCloud-Links hinzufügen
- ✅ **Compact & Visual Player** - Verschiedene Player-Modi für verschiedene Screens
- ✅ **Genre-Integration** - SoundCloud als erste Option im Radio Player (☁️ SoundCloud)

---

## 📦 Verfügbare Widgets

### 1. **SoundCloudPlayer** (Basis-Widget)

**Verwendung:**
```dart
import '../widgets/soundcloud_player.dart';

SoundCloudPlayer(
  trackUrl: 'https://soundcloud.com/artist/track',
  autoPlay: true,
  showArtwork: true,
  accentColor: Color(0xFF8B5CF6),
  height: 166,
)
```

**Parameter:**
- `trackUrl` - SoundCloud Track/Playlist URL
- `autoPlay` - Automatisches Abspielen (default: false)
- `showArtwork` - Zeige Album-Artwork (default: true)
- `accentColor` - UI-Farbe des Players (default: #8B5CF6)
- `height` - Player-Höhe in Pixel (default: 166)

**Features:**
- WebView-basierte Embed-Integration
- SoundCloud Widget API
- Loading-Indicator während Initialisierung
- Error-Handling für fehlgeschlagene Loads

---

### 2. **SoundCloudCompactPlayer** (Minimal-Version)

**Verwendung:**
```dart
SoundCloudCompactPlayer(
  trackUrl: 'https://soundcloud.com/artist/track',
  autoPlay: false,
)
```

**Eigenschaften:**
- Nur Waveform (kein Artwork)
- Höhe: 120px (kompakter)
- Perfekt für Chat-Integration
- SoundCloud Orange Accent (#FF5500)

---

### 3. **SoundCloudVisualPlayer** (Vollbild-Version)

**Verwendung:**
```dart
SoundCloudVisualPlayer(
  trackUrl: 'https://soundcloud.com/artist/track',
  autoPlay: true,
)
```

**Eigenschaften:**
- Volle Artwork-Anzeige
- Höhe: 400px (groß)
- Auto-Play aktiviert
- Gold Accent (#FFD700)
- Ideal für dedizierte Musik-Screens

---

### 4. **SoundCloudPlaylistPlayer** (Playlist-Version)

**Verwendung:**
```dart
SoundCloudPlaylistPlayer(
  playlistUrl: 'https://soundcloud.com/artist/sets/playlist',
  autoPlay: false,
)
```

**Eigenschaften:**
- Höhe: 450px (höher für Playlist-Ansicht)
- Zeigt alle Tracks in Playlist
- Scroll-Support für lange Playlists

---

### 5. **MusicSoundCloudWidget** (Chat-Integration)

**Verwendung:**
```dart
import '../widgets/music_soundcloud_widget.dart';

MusicSoundCloudWidget(
  isExpanded: true,
)
```

**Features:**
- 5 kuratierte Playlists:
  - 😌 Chill Vibes (Lo-Fi Hip Hop)
  - 🎧 Electronic Mix (EDM)
  - 🎤 Hip Hop Beats
  - 🏠 Deep House
  - 🎨 Indie Favorites
- Custom URL Input
- Compact/Expanded Views
- Playlist-Grid mit Genre-Icons

---

## 🔧 Integration im Musik-Chat

### Enhanced Radio Player

SoundCloud ist jetzt **erste Genre-Option**:

```dart
// In lib/widgets/enhanced_radio_player.dart
static const List<Map<String, String>> _musicGenres = [
  {'name': 'soundcloud', 'display': '☁️ SoundCloud', 'color': 'FF5500'}, // FIRST!
  {'name': 'pop', 'display': '🎤 Pop', 'color': 'FF6B9D'},
  // ... 30 weitere Radio-Genres
];
```

**User-Flow:**
1. User öffnet Musik-Chat
2. Klickt auf "☁️ SoundCloud" Genre-Button
3. Expandierter Player zeigt kuratierte Playlists
4. User wählt Playlist oder fügt eigene URL hinzu
5. SoundCloud Player startet automatisch

---

## 🎨 SoundCloud Helper

**Utility-Funktionen für SoundCloud-URLs:**

```dart
import '../widgets/soundcloud_player.dart';

// URL-Validierung
bool isValid = SoundCloudHelper.isValidSoundCloudUrl(url);

// Track-ID extrahieren
String? trackId = SoundCloudHelper.extractTrackId(url);

// URL-Builder
String trackUrl = SoundCloudHelper.buildTrackUrl('username', 'track-slug');
String playlistUrl = SoundCloudHelper.buildPlaylistUrl('username', 'playlist-slug');
```

---

## 📋 Kuratierte Playlists

**Standard-Playlists (Beispiele - anpassbar):**

1. **😌 Chill Vibes**
   - Genre: Lo-Fi Hip Hop
   - Color: #03A9F4 (Cyan)
   - URL: `https://soundcloud.com/chilledcow/sets/lofi-hip-hop-radio`

2. **🎧 Electronic Mix**
   - Genre: EDM/Electronic
   - Color: #00D2FF (Electric Blue)
   - URL: `https://soundcloud.com/monstercat/sets/monstercat-best-of-edm`

3. **🎤 Hip Hop Beats**
   - Genre: Hip Hop/Rap
   - Color: #FF9800 (Orange)
   - URL: `https://soundcloud.com/hiphopbeats/sets/best-rap-beats`

4. **🏠 Deep House**
   - Genre: House/Deep House
   - Color: #9C27B0 (Purple)
   - URL: `https://soundcloud.com/deephouse/sets/deep-house-essentials`

5. **🎨 Indie Favorites**
   - Genre: Indie/Alternative
   - Color: #607D8B (Blue Grey)
   - URL: `https://soundcloud.com/indiemusic/sets/indie-favorites`

**Hinweis:** URLs sind Beispiele - ersetze mit tatsächlichen SoundCloud Playlists.

---

## 🚀 Verwendungs-Beispiele

### Beispiel 1: Compact Player in Chat

```dart
// In Chat-Screen, wenn backgroundTheme == 'music'
if (selectedGenre == 'soundcloud') {
  SoundCloudCompactPlayer(
    trackUrl: 'https://soundcloud.com/artist/track',
    autoPlay: true,
  )
} else {
  EnhancedRadioPlayer(
    activeUserCount: chatRoom.memberCount,
  )
}
```

### Beispiel 2: Full Player in Musik-Screen

```dart
// Dedizierter Musik-Screen
SoundCloudVisualPlayer(
  trackUrl: currentTrackUrl,
  autoPlay: true,
)
```

### Beispiel 3: Playlist-Browser

```dart
// Playlist-Auswahl Screen
ListView.builder(
  itemCount: playlists.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(playlists[index].name),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SoundCloudPlaylistPlayer(
              playlistUrl: playlists[index].url,
            ),
          ),
        );
      },
    );
  },
)
```

---

## 🔒 Wichtige Hinweise

### WebView-Berechtigungen

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### HTTPS-Only

- ✅ SoundCloud URLs müssen HTTPS sein
- ✅ WebView erfordert sichere Verbindungen
- ❌ HTTP-URLs werden blockiert

### SoundCloud Embed Limits

- ✅ Keine API-Key erforderlich für Embed
- ✅ Öffentliche Tracks/Playlists funktionieren sofort
- ❌ Private Tracks benötigen spezielle Permissions
- ❌ Download-Links nicht über Embed verfügbar

### Performance

**Memory-Verbrauch:**
- SoundCloud Player: ~50-80 MB RAM
- Radio Player: ~30-50 MB RAM
- Empfehlung: Nur 1 Player gleichzeitig aktiv

**Network-Verbrauch:**
- Streaming: ~128 kbps (variabel)
- Initial Load: ~2-5 MB (Player + Artwork)

---

## 🎯 Best Practices

### 1. **Verwende Compact Player für Listen**
```dart
// ✅ RICHTIG: Kompakter Player in Chat
SoundCloudCompactPlayer(trackUrl: url)

// ❌ FALSCH: Voller Player in Chat (zu groß)
SoundCloudVisualPlayer(trackUrl: url)
```

### 2. **Validiere URLs vor dem Laden**
```dart
// ✅ RICHTIG: Validierung
if (SoundCloudHelper.isValidSoundCloudUrl(url)) {
  loadPlayer(url);
} else {
  showError('Ungültige URL');
}

// ❌ FALSCH: Direkt laden (kann crashen)
loadPlayer(url);
```

### 3. **Auto-Play nur in Fullscreen**
```dart
// ✅ RICHTIG: Auto-Play in dediziertem Screen
SoundCloudVisualPlayer(trackUrl: url, autoPlay: true)

// ❌ FALSCH: Auto-Play in Listen (nervt User)
SoundCloudCompactPlayer(trackUrl: url, autoPlay: true)
```

### 4. **Cleanup bei Dispose**
```dart
@override
void dispose() {
  // WebView wird automatisch disposed
  // Aber: Stop playback bei Navigation
  super.dispose();
}
```

---

## 📈 Performance-Optimierung

### Lazy Loading

```dart
// ✅ RICHTIG: Lade Player nur wenn sichtbar
if (isVisible) {
  SoundCloudPlayer(trackUrl: url)
} else {
  Placeholder()
}
```

### Preloading (Optional)

```dart
// Pre-load häufig genutzte Playlists
RoutePreloaderService().preload(
  'soundcloud_chill',
  () => SoundCloudPlayer(trackUrl: chillVibesUrl),
);
```

---

## 🔄 Migration von YouTube zu SoundCloud

**Vorher (YouTube):**
```dart
YoutubePlayer(
  controller: YoutubePlayerController(...),
)
```

**Nachher (SoundCloud):**
```dart
SoundCloudPlayer(
  trackUrl: 'https://soundcloud.com/artist/track',
  autoPlay: true,
)
```

**Vorteile:**
- ✅ Einfachere Integration (keine Controller)
- ✅ Keine API-Key erforderlich
- ✅ Bessere Performance (optimiertes Embed)
- ✅ Musik-fokussiert (keine Videos)

---

## 📚 Weitere Ressourcen

- [SoundCloud Widget API Docs](https://developers.soundcloud.com/docs/api/html5-widget)
- [WebView Flutter Package](https://pub.dev/packages/webview_flutter)
- [SoundCloud für Entwickler](https://developers.soundcloud.com/)

---

**Version:** v3.9.962  
**Letzte Aktualisierung:** Phase 2 - SoundCloud Integration  
**Autor:** Weltenbibliothek Development Team
