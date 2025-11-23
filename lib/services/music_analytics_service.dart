import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MusicAnalyticsService extends ChangeNotifier {
  static const String _boxName = 'music_analytics';
  Box? _box;
  final Map<String, DateTime> _userSessionStart = {};

  Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_boxName);
      if (kDebugMode) {
        debugPrint('✅ Analytics Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics init error: $e');
      }
    }
  }

  Future<void> trackGenrePlay(String genreId) async {
    if (_box == null) return;
    try {
      final key = 'genre_$genreId';
      final count = _box!.get(key, defaultValue: 0) as int;
      await _box!.put(key, count + 1);

      final totalKey = 'total_genre_plays';
      final total = _box!.get(totalKey, defaultValue: 0) as int;
      await _box!.put(totalKey, total + 1);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Track genre error: $e');
      }
    }
  }

  void startSession(String userId) {
    _userSessionStart[userId] = DateTime.now();
    if (kDebugMode) {
      debugPrint('🎵 Session started: $userId');
    }
  }

  Future<void> trackTrackPlayed(String userId) async {
    if (_box == null) return;
    try {
      final userKey = 'user_tracks_$userId';
      final count = _box!.get(userKey, defaultValue: 0) as int;
      await _box!.put(userKey, count + 1);

      final totalKey = 'total_tracks_played';
      final total = _box!.get(totalKey, defaultValue: 0) as int;
      await _box!.put(totalKey, total + 1);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Track played error: $e');
      }
    }
  }

  Future<void> endSession(String userId) async {
    if (_box == null || !_userSessionStart.containsKey(userId)) return;

    try {
      final start = _userSessionStart[userId]!;
      final duration = DateTime.now().difference(start);
      final minutes = duration.inMinutes;

      final userKey = 'user_time_$userId';
      final total = _box!.get(userKey, defaultValue: 0) as int;
      await _box!.put(userKey, total + minutes);

      final globalKey = 'total_listening_minutes';
      final globalTotal = _box!.get(globalKey, defaultValue: 0) as int;
      await _box!.put(globalKey, globalTotal + minutes);

      _userSessionStart.remove(userId);

      if (kDebugMode) {
        debugPrint('🎵 Session ended: $userId ($minutes min)');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ End session error: $e');
      }
    }
  }

  List<Map<String, dynamic>> getTopGenres(List<String> allGenreIds) {
    if (_box == null) return [];

    final genreStats = <Map<String, dynamic>>[];

    for (final id in allGenreIds) {
      final count = _box!.get('genre_$id', defaultValue: 0) as int;
      if (count > 0) {
        genreStats.add({'genreId': id, 'playCount': count});
      }
    }

    genreStats.sort(
      (a, b) => (b['playCount'] as int).compareTo(a['playCount'] as int),
    );
    return genreStats.take(10).toList();
  }

  List<Map<String, dynamic>> getTopListeners(List<String> userIds) {
    if (_box == null) return [];

    final stats = <Map<String, dynamic>>[];

    for (final userId in userIds) {
      final time = _box!.get('user_time_$userId', defaultValue: 0) as int;
      if (time > 0) {
        stats.add({'userId': userId, 'listeningTime': time});
      }
    }

    stats.sort(
      (a, b) =>
          (b['listeningTime'] as int).compareTo(a['listeningTime'] as int),
    );
    return stats.take(10).toList();
  }

  Map<String, int> getGlobalStats() {
    if (_box == null) return {};

    return {
      'total_genre_plays':
          _box!.get('total_genre_plays', defaultValue: 0) as int,
      'total_tracks_played':
          _box!.get('total_tracks_played', defaultValue: 0) as int,
      'total_listening_minutes':
          _box!.get('total_listening_minutes', defaultValue: 0) as int,
    };
  }

  Map<String, int> getUserStats(String userId) {
    if (_box == null) return {};

    return {
      'tracks_played': _box!.get('user_tracks_$userId', defaultValue: 0) as int,
      'listening_time': _box!.get('user_time_$userId', defaultValue: 0) as int,
    };
  }
}
