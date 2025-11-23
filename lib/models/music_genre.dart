/// 🎼 Music Genre Enum
/// 26 Musik-Genres für Weltenbibliothek
enum MusicGenre {
  pop('Pop', '🎵'),
  rock('Rock', '🎸'),
  hipHop('Hip-Hop', '🎤'),
  rnb('R&B', '🎶'),
  soul('Soul', '✨'),
  funk('Funk', '🕺'),
  edm('EDM', '⚡'),
  house('House', '🏠'),
  electro('Electro', '🔊'),
  techno('Techno', '🤖'),
  trance('Trance', '🌀'),
  dubstep('Dubstep', '💥'),
  drumBass('Drum&Bass', '🥁'),
  jazz('Jazz', '🎺'),
  blues('Blues', '🎹'),
  country('Country', '🤠'),
  folk('Folk', '🪕'),
  reggae('Reggae', '🌴'),
  latin('Latin', '🔥'),
  salsa('Salsa', '💃'),
  metal('Metal', '🤘'),
  punk('Punk', '💀'),
  alternative('Alternative', '🎧'),
  indie('Indie', '🌟'),
  classical('Classical', '🎻'),
  ambient('Ambient', '☁️');

  final String displayName;
  final String emoji;

  const MusicGenre(this.displayName, this.emoji);

  /// Genre-Name mit Emoji
  String get displayWithEmoji => '$emoji $displayName';

  /// Finde Genre nach Display-Name
  static MusicGenre? fromDisplayName(String name) {
    try {
      return MusicGenre.values.firstWhere(
        (g) => g.displayName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Alle Genre-Namen (für Cloudflare Worker API)
  static List<String> get allDisplayNames {
    return MusicGenre.values.map((g) => g.displayName).toList();
  }

  /// Genre in Grid-Reihen aufteilen (4 pro Reihe)
  static List<List<MusicGenre>> get gridRows {
    final genres = MusicGenre.values;
    final rows = <List<MusicGenre>>[];

    for (int i = 0; i < genres.length; i += 4) {
      final end = (i + 4 > genres.length) ? genres.length : i + 4;
      rows.add(genres.sublist(i, end));
    }

    return rows;
  }

  /// Finde Genre nach ID (enum name)
  static MusicGenre? findById(String id) {
    try {
      return MusicGenre.values.firstWhere((g) => g.name == id);
    } catch (e) {
      return null;
    }
  }

  /// Aus String erstellen (enum name oder displayName)
  static MusicGenre fromString(String value) {
    // Versuche zuerst enum name
    try {
      return MusicGenre.values.firstWhere(
        (g) => g.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      // Dann displayName
      return fromDisplayName(value) ?? MusicGenre.pop;
    }
  }

  /// Icon Getter (emoji)
  String get icon => emoji;
}
