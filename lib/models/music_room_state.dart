import 'music_track.dart';
import 'music_genre.dart';

/// 🎵 Musik-Raum State (Shared zwischen allen Teilnehmern)
class MusicRoomState {
  final MusicTrack? currentSong;
  final MusicGenre? currentGenre;
  final int playbackPosition; // Millisekunden
  final bool isPlaying;
  final bool isMusicEnabledGlobally; // Für Livestream-Priorität
  final int volume; // 0-100
  final List<String> playlist; // Video-IDs
  final int playlistIndex;
  final int participantCount;
  final int maxVolume; // Dynamisch basierend auf Teilnehmerzahl
  final DateTime lastUpdated;

  MusicRoomState({
    this.currentSong,
    this.currentGenre,
    this.playbackPosition = 0,
    this.isPlaying = false,
    this.isMusicEnabledGlobally = true,
    this.volume = 100,
    this.playlist = const [],
    this.playlistIndex = 0,
    this.participantCount = 0,
    int? maxVolume,
    DateTime? lastUpdated,
  }) : maxVolume = maxVolume ?? _calculateMaxVolume(participantCount),
       lastUpdated = lastUpdated ?? DateTime.now();

  /// Berechne maximale Lautstärke basierend auf Teilnehmerzahl
  static int _calculateMaxVolume(int participants) {
    if (participants <= 1) return 100;
    if (participants == 2) return 50;
    return 10; // 3+ Teilnehmer
  }

  /// Von JSON erstellen
  factory MusicRoomState.fromJson(Map<String, dynamic> json) {
    final stateData = json['state'] as Map<String, dynamic>? ?? json;

    return MusicRoomState(
      currentSong: stateData['currentSong'] != null
          ? MusicTrack.fromJson(
              stateData['currentSong'] as Map<String, dynamic>,
            )
          : null,
      currentGenre: stateData['currentGenre'] != null
          ? MusicGenre.fromString(stateData['currentGenre'] as String)
          : null,
      playbackPosition: stateData['playbackPosition'] as int? ?? 0,
      isPlaying: stateData['isPlaying'] as bool? ?? false,
      isMusicEnabledGlobally:
          stateData['isMusicEnabledGlobally'] as bool? ?? true,
      volume: stateData['volume'] as int? ?? 100,
      playlist:
          (stateData['playlist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      playlistIndex: stateData['playlistIndex'] as int? ?? 0,
      participantCount: json['participantCount'] as int? ?? 0,
      maxVolume: json['maxVolume'] as int?,
      lastUpdated: stateData['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(stateData['lastUpdated'] as int)
          : DateTime.now(),
    );
  }

  /// Zu JSON konvertieren
  Map<String, dynamic> toJson() {
    return {
      'currentSong': currentSong?.toJson(),
      'currentGenre': currentGenre?.displayName,
      'playbackPosition': playbackPosition,
      'isPlaying': isPlaying,
      'isMusicEnabledGlobally': isMusicEnabledGlobally,
      'volume': volume,
      'playlist': playlist,
      'playlistIndex': playlistIndex,
      'participantCount': participantCount,
      'maxVolume': maxVolume,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  /// Kopie mit geänderten Werten
  MusicRoomState copyWith({
    MusicTrack? currentSong,
    MusicGenre? currentGenre,
    int? playbackPosition,
    bool? isPlaying,
    bool? isMusicEnabledGlobally,
    int? volume,
    List<String>? playlist,
    int? playlistIndex,
    int? participantCount,
    int? maxVolume,
    DateTime? lastUpdated,
  }) {
    final newParticipantCount = participantCount ?? this.participantCount;

    return MusicRoomState(
      currentSong: currentSong ?? this.currentSong,
      currentGenre: currentGenre ?? this.currentGenre,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      isMusicEnabledGlobally:
          isMusicEnabledGlobally ?? this.isMusicEnabledGlobally,
      volume: volume ?? this.volume,
      playlist: playlist ?? this.playlist,
      playlistIndex: playlistIndex ?? this.playlistIndex,
      participantCount: newParticipantCount,
      maxVolume: maxVolume ?? _calculateMaxVolume(newParticipantCount),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Ist Musik spielbar?
  bool get canPlay => currentSong != null && isMusicEnabledGlobally;

  /// Gibt es einen nächsten Song?
  bool get hasNextSong =>
      playlist.isNotEmpty && playlistIndex < playlist.length - 1;

  /// Gibt es einen vorherigen Song?
  bool get hasPreviousSong => playlist.isNotEmpty && playlistIndex > 0;

  @override
  String toString() =>
      'MusicRoomState(song: ${currentSong?.title}, playing: $isPlaying, participants: $participantCount)';
}
