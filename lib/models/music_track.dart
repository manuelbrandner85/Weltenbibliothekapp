/// 🎵 Music Track Model
/// Repräsentiert einen Musik-Track mit Audio-Stream-URL von yt-dlp Worker
class MusicTrack {
  final String videoId;
  final String title;
  final String artist;
  final int duration; // in Sekunden
  final String thumbnailUrl;
  final String audioUrl; // Direkte Stream-URL von yt-dlp Worker
  final String format;
  final int bitrate;

  const MusicTrack({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumbnailUrl,
    required this.audioUrl,
    required this.format,
    required this.bitrate,
  });

  /// Factory: Aus yt-dlp Worker Response erstellen
  factory MusicTrack.fromYtDlpResponse(Map<String, dynamic> json) {
    final videoInfo = json['videoInfo'] as Map<String, dynamic>;

    return MusicTrack(
      videoId: json['videoId'] as String,
      title: videoInfo['title'] as String,
      artist: videoInfo['artist'] as String,
      duration: videoInfo['duration'] as int,
      thumbnailUrl: videoInfo['thumbnailUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      format: videoInfo['format'] as String,
      bitrate: videoInfo['bitrate'] as int,
    );
  }

  /// Factory: Aus JSON erstellen
  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      duration: json['duration'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      format: json['format'] as String? ?? 'unknown',
      bitrate: json['bitrate'] as int? ?? 128000,
    );
  }

  /// Zu JSON konvertieren
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'artist': artist,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
      'format': format,
      'bitrate': bitrate,
    };
  }

  /// Duration als formatierter String (z.B. "3:45")
  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'MusicTrack(title: $title, artist: $artist, duration: $durationFormatted)';
  }
}
