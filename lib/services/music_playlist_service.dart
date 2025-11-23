import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🎵 Musik-Playlist Service für Weltenbibliothek
///
/// Verwaltet Musik-Playlists mit Cloudflare KV Backend und lokaler Hive-Synchronisation
class MusicPlaylistService {
  static const String _boxName = 'music_playlists';
  static const String _apiBaseUrl = 'https://your-worker.workers.dev/api';

  late Box _box;
  bool _isInitialized = false;

  /// Initialisiere Hive Box
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ MusicPlaylistService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize MusicPlaylistService: $e');
      }
    }
  }

  /// Hole alle Playlists (zuerst lokal, dann sync)
  Future<List<MusicPlaylist>> getPlaylists({
    required String userId,
    bool forceSync = false,
  }) async {
    // Lade lokale Playlists
    final localPlaylists = _getLocalPlaylists(userId);

    // Sync mit Server wenn gewünscht
    if (forceSync) {
      await _syncWithServer(userId);
      return _getLocalPlaylists(userId);
    }

    return localPlaylists;
  }

  /// Erstelle neue Playlist
  Future<MusicPlaylist?> createPlaylist({
    required String userId,
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    try {
      final playlist = MusicPlaylist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        tracks: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Speichere lokal
      await _savePlaylistLocally(playlist);

      // Sync mit Server
      await _uploadPlaylistToServer(playlist);

      if (kDebugMode) {
        debugPrint('✅ Playlist created: ${playlist.name}');
      }

      return playlist;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating playlist: $e');
      }
      return null;
    }
  }

  /// Füge Track zu Playlist hinzu
  Future<bool> addTrack({
    required String playlistId,
    required String userId,
    required MusicTrack track,
  }) async {
    try {
      final playlists = _getLocalPlaylists(userId);
      final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);

      if (playlistIndex == -1) {
        if (kDebugMode) {
          debugPrint('❌ Playlist not found: $playlistId');
        }
        return false;
      }

      final playlist = playlists[playlistIndex];

      // Prüfe ob Track bereits existiert
      if (playlist.tracks.any((t) => t.id == track.id)) {
        if (kDebugMode) {
          debugPrint('⚠️ Track already in playlist: ${track.title}');
        }
        return false;
      }

      // Füge Track hinzu
      playlist.tracks.add(track);
      playlist.updatedAt = DateTime.now();

      // Speichere lokal
      await _savePlaylistLocally(playlist);

      // Sync mit Server
      await _uploadPlaylistToServer(playlist);

      if (kDebugMode) {
        debugPrint('✅ Track added to playlist: ${track.title}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding track: $e');
      }
      return false;
    }
  }

  /// Entferne Track von Playlist
  Future<bool> removeTrack({
    required String playlistId,
    required String userId,
    required String trackId,
  }) async {
    try {
      final playlists = _getLocalPlaylists(userId);
      final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);

      if (playlistIndex == -1) return false;

      final playlist = playlists[playlistIndex];
      playlist.tracks.removeWhere((t) => t.id == trackId);
      playlist.updatedAt = DateTime.now();

      await _savePlaylistLocally(playlist);
      await _uploadPlaylistToServer(playlist);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing track: $e');
      }
      return false;
    }
  }

  /// Lösche Playlist
  Future<bool> deletePlaylist({
    required String playlistId,
    required String userId,
  }) async {
    try {
      // Lösche lokal
      await _box.delete('playlist_$playlistId');

      // Lösche auf Server
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/playlists/$playlistId'),
        headers: {'X-User-ID': userId},
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting playlist: $e');
      }
      return false;
    }
  }

  /// Sync Playlists mit Server
  Future<void> syncPlaylists(String userId) async {
    await _syncWithServer(userId);
  }

  // Private Helper Methods

  List<MusicPlaylist> _getLocalPlaylists(String userId) {
    final playlists = <MusicPlaylist>[];

    for (final key in _box.keys) {
      if (key.toString().startsWith('playlist_')) {
        try {
          final data = _box.get(key) as Map<dynamic, dynamic>;
          final playlist = MusicPlaylist.fromJson(
            Map<String, dynamic>.from(data),
          );

          if (playlist.userId == userId) {
            playlists.add(playlist);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error parsing playlist $key: $e');
          }
        }
      }
    }

    // Sortiere nach Update-Zeit
    playlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return playlists;
  }

  Future<void> _savePlaylistLocally(MusicPlaylist playlist) async {
    await _box.put('playlist_${playlist.id}', playlist.toJson());
  }

  Future<void> _uploadPlaylistToServer(MusicPlaylist playlist) async {
    try {
      await http.post(
        Uri.parse('$_apiBaseUrl/playlists/${playlist.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-ID': playlist.userId,
        },
        body: jsonEncode(playlist.toJson()),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading playlist to server: $e');
      }
    }
  }

  Future<void> _syncWithServer(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists'),
        headers: {'X-User-ID': userId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        for (final item in data) {
          final playlist = MusicPlaylist.fromJson(item as Map<String, dynamic>);
          await _savePlaylistLocally(playlist);
        }

        if (kDebugMode) {
          debugPrint('✅ Synced ${data.length} playlists from server');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error syncing with server: $e');
      }
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}

/// Musik-Playlist Model
class MusicPlaylist {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<MusicTrack> tracks;
  final DateTime createdAt;
  DateTime updatedAt;

  MusicPlaylist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.tracks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MusicPlaylist.fromJson(Map<String, dynamic> json) {
    return MusicPlaylist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      tracks:
          (json['tracks'] as List<dynamic>?)
              ?.map((t) => MusicTrack.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get trackCount => tracks.length;

  Duration get totalDuration {
    return tracks.fold(Duration.zero, (sum, track) => sum + track.duration);
  }
}

/// Musik-Track Model
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? albumName;
  final String? albumArtUrl;
  final Duration duration;
  final String audioUrl;
  final Map<String, dynamic>? metadata;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.albumName,
    this.albumArtUrl,
    required this.duration,
    required this.audioUrl,
    this.metadata,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumName: json['album_name'] as String?,
      albumArtUrl: json['album_art_url'] as String?,
      duration: Duration(seconds: json['duration_seconds'] as int),
      audioUrl: json['audio_url'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album_name': albumName,
      'album_art_url': albumArtUrl,
      'duration_seconds': duration.inSeconds,
      'audio_url': audioUrl,
      'metadata': metadata,
    };
  }

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
