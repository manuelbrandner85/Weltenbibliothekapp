import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/music_track.dart';
import '../models/music_genre.dart';

/// 🎵 Music Sync Service
/// Verbindet Flutter App mit Cloudflare Workers für synchronisierte Musik-Wiedergabe
class MusicSyncService {
  // Cloudflare Worker URLs
  static const String _ytdlpWorkerUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';
  static const String _syncWorkerUrl =
      'https://weltenbibliothek.brandy13062.workers.dev';
  static const String _wsUrl = 'wss://weltenbibliothek.brandy13062.workers.dev';

  // WebSocket Verbindung
  WebSocketChannel? _wsChannel;
  final StreamController<Map<String, dynamic>> _stateController =
      StreamController.broadcast();

  // Aktueller Raum
  String? _currentRoomId;

  /// Stream für Sync-State Updates
  Stream<Map<String, dynamic>> get stateUpdates => _stateController.stream;

  /// Ist mit WebSocket verbunden?
  bool get isConnected => _wsChannel != null;

  /// Aktueller Raum
  String? get currentRoomId => _currentRoomId;

  // ==========================================
  // YT-DLP WORKER API
  // ==========================================

  /// Extrahiere Audio-Stream-URL für Video-ID
  Future<MusicTrack?> extractAudioUrl(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_ytdlpWorkerUrl/extract-audio/$videoId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return MusicTrack.fromYtDlpResponse(data);
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Audio-Extraktion fehlgeschlagen: $e');
      }
      return null;
    }
  }

  /// Suche Videos für Genre
  Future<List<String>> searchGenre(MusicGenre genre) async {
    try {
      final response = await http.get(
        Uri.parse('$_ytdlpWorkerUrl/genre/${genre.displayName}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final videoIds = (data['videoIds'] as List).cast<String>();
          return videoIds;
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Genre-Suche fehlgeschlagen: $e');
      }
      return [];
    }
  }

  /// Hole alle verfügbaren Genres vom Worker
  Future<List<String>> fetchAvailableGenres() async {
    try {
      final response = await http.get(Uri.parse('$_ytdlpWorkerUrl/genres'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return (data['genres'] as List).cast<String>();
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Genre-Liste-Abruf fehlgeschlagen: $e');
      }
      return [];
    }
  }

  // ==========================================
  // SYNC WORKER API (Durable Objects)
  // ==========================================

  /// Verbinde zu Musik-Raum via WebSocket
  Future<bool> connectToRoom(String roomId) async {
    try {
      // Trenne alte Verbindung
      await disconnect();

      _currentRoomId = roomId;

      // WebSocket URL für Raum
      final wsUri = Uri.parse('$_wsUrl/room/$roomId/ws');

      _wsChannel = WebSocketChannel.connect(wsUri);

      // Höre auf Updates
      _wsChannel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message as String) as Map<String, dynamic>;
            _stateController.add(data);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ WebSocket Message Parse Error: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('❌ WebSocket Error: $error');
          }
          disconnect();
        },
        onDone: () {
          if (kDebugMode) {
            debugPrint('🔌 WebSocket Verbindung geschlossen');
          }
          disconnect();
        },
      );

      if (kDebugMode) {
        debugPrint('✅ Mit Raum "$roomId" verbunden');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Verbindung fehlgeschlagen: $e');
      }
      return false;
    }
  }

  /// Trenne WebSocket-Verbindung
  Future<void> disconnect() async {
    await _wsChannel?.sink.close();
    _wsChannel = null;
    _currentRoomId = null;
  }

  /// Setze Genre für aktuellen Raum
  Future<MusicTrack?> setGenre(MusicGenre genre) async {
    if (_currentRoomId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_syncWorkerUrl/room/$_currentRoomId/set-genre'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'genre': genre.displayName}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final songData = data['song'] as Map<String, dynamic>;

          // Extrahiere vollständige Audio-URL vom yt-dlp Worker
          final track = await extractAudioUrl(songData['videoId'] as String);
          return track;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Genre setzen fehlgeschlagen: $e');
      }
      return null;
    }
  }

  /// Nächster Song
  Future<MusicTrack?> nextSong() async {
    if (_currentRoomId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_syncWorkerUrl/room/$_currentRoomId/next-song'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final songData = data['song'] as Map<String, dynamic>;
          final track = await extractAudioUrl(songData['videoId'] as String);
          return track;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nächster Song fehlgeschlagen: $e');
      }
      return null;
    }
  }

  /// Play/Pause umschalten
  Future<bool> togglePlayPause(bool isPlaying) async {
    if (_currentRoomId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_syncWorkerUrl/room/$_currentRoomId/play-pause'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isPlaying': isPlaying}),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Play/Pause fehlgeschlagen: $e');
      }
      return false;
    }
  }

  /// Setze Lautstärke
  Future<bool> setVolume(double volume) async {
    if (_currentRoomId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_syncWorkerUrl/room/$_currentRoomId/set-volume'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'volume': volume.toInt()}),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Lautstärke setzen fehlgeschlagen: $e');
      }
      return false;
    }
  }

  /// Sende Playback-Position (für Sync)
  void sendPlaybackPosition(double position) {
    if (_wsChannel == null) return;

    try {
      _wsChannel!.sink.add(
        json.encode({'type': 'position_update', 'position': position}),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Position senden fehlgeschlagen: $e');
      }
    }
  }

  /// Cleanup
  void dispose() {
    disconnect();
    _stateController.close();
  }
}
