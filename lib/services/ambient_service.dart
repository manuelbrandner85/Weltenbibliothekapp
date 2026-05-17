// 🌅 Ambient Daily Path Service
//
// Holt den täglichen Pfad (3 Aktivitäten + Insight + Frequenz) vom
// Cloudflare Worker. Cached pro Tag in SharedPreferences.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'device_location_service.dart';
import 'gamification_service.dart';

/// Eine einzelne Aktivität im Tagespfad.
class Activity {
  final String title;
  final String description;
  final int durationMin;
  final String? moduleCode;
  final String world;
  final String icon;

  const Activity({
    required this.title,
    required this.description,
    required this.durationMin,
    required this.world,
    required this.icon,
    this.moduleCode,
  });

  factory Activity.fromJson(Map<String, dynamic> j) {
    return Activity(
      title: (j['title'] as String?) ?? 'Aktivität',
      description: (j['description'] as String?) ?? '',
      durationMin: (j['duration_min'] as num?)?.toInt() ?? 10,
      moduleCode: j['module_code'] as String?,
      world: (j['world'] as String?) ?? 'materie',
      icon: (j['icon'] as String?) ?? '✨',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'duration_min': durationMin,
        'module_code': moduleCode,
        'world': world,
        'icon': icon,
      };
}

/// Der komplette Tagespfad.
class DailyPath {
  final List<Activity> activities;
  final String dailyInsight;
  final double ambientFrequency;
  final Map<String, dynamic> context;
  final DateTime generatedAt;

  const DailyPath({
    required this.activities,
    required this.dailyInsight,
    required this.ambientFrequency,
    required this.context,
    required this.generatedAt,
  });

  factory DailyPath.fromJson(Map<String, dynamic> j) {
    final rawActivities = (j['activities'] as List?) ?? const [];
    return DailyPath(
      activities: rawActivities
          .whereType<Map>()
          .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      dailyInsight: (j['dailyInsight'] as String?) ??
          (j['daily_insight'] as String?) ??
          '',
      ambientFrequency:
          ((j['ambientFrequency'] ?? j['ambient_frequency']) as num?)
                  ?.toDouble() ??
              7.83,
      context: j['context'] is Map
          ? Map<String, dynamic>.from(j['context'] as Map)
          : <String, dynamic>{},
      generatedAt: DateTime.tryParse(
            (j['generatedAt'] as String?) ??
                (j['generated_at'] as String?) ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'activities': activities.map((a) => a.toJson()).toList(),
        'dailyInsight': dailyInsight,
        'ambientFrequency': ambientFrequency,
        'context': context,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

/// Singleton-Service für den Tagespfad.
class AmbientService {
  AmbientService._();
  static final AmbientService instance = AmbientService._();

  static const _kMoodKey = 'ambient_mood';
  static const _kCachePrefix = 'ambient_daily_path_';

  /// Bestimme Tageszeit-Bucket (morning/afternoon/evening/night).
  String _timeOfDay() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return 'morning';
    if (h >= 12 && h < 18) return 'afternoon';
    if (h >= 18 && h < 22) return 'evening';
    return 'night';
  }

  String _todayKey() {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$_kCachePrefix$y-$m-$d';
  }

  /// Cache-Key inkludiert gerundete GPS-Position (0.5° Granularität),
  /// damit ein Standortwechsel den Tages-Cache invalidiert und neues
  /// Wetter geladen wird.
  String _todayKeyForLocation(DeviceLocation? loc) {
    final base = _todayKey();
    if (loc == null) return base;
    final latBucket = (loc.lat * 2).round();
    final lngBucket = (loc.lng * 2).round();
    return '$base-$latBucket,$lngBucket';
  }

  /// Liest die letzte Stimmung des Users (oder 'neutral').
  Future<String> getMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kMoodKey) ?? 'neutral';
    } catch (_) {
      return 'neutral';
    }
  }

  /// Speichert die aktuelle Stimmung des Users.
  Future<void> setMood(String mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMoodKey, mood);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ AmbientService.setMood: $e');
    }
  }

  /// Wählt die dominante Welt mit der höchsten XP.
  String _dominantWorld(GamificationService g) {
    const worlds = ['materie', 'energie', 'noir', 'genesis'];
    String best = 'materie';
    int bestXp = -1;
    for (final w in worlds) {
      final xp = g.getProgress(w).totalXp;
      if (xp > bestXp) {
        bestXp = xp;
        best = w;
      }
    }
    return best;
  }

  int _maxStreak(GamificationService g) {
    const worlds = ['materie', 'energie', 'noir', 'genesis'];
    int s = 0;
    for (final w in worlds) {
      final cur = g.getProgress(w).streakDays;
      if (cur > s) s = cur;
    }
    return s;
  }

  /// Lädt den Tagespfad (mit Cache pro Datum).
  Future<DailyPath?> loadDailyPath({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Standort vorab holen — Cache-Key enthält gerundete Position
    // (0.5° ≈ 55 km), damit ein Stadtwechsel den Cache invalidiert.
    final loc = await DeviceLocationService.instance.getCurrent();
    final cacheKey = _todayKeyForLocation(loc);

    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          return DailyPath.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
          );
        } catch (_) {
          // fallthrough zu Netzwerk-Fetch
        }
      }
    }

    try {
      final g = GamificationService();
      final dominant = _dominantWorld(g);
      final level = g.globalLevel;
      final streak = _maxStreak(g);
      final mood = await getMood();

      final body = <String, dynamic>{
        'userId': null,
        'timeOfDay': _timeOfDay(),
        'lastModules': <String>[],
        'streak': streak,
        'level': level,
        'dominantWorld': dominant,
        'hrvBaseline': null,
        'moodCheckIn': mood,
        if (loc != null) 'lat': loc.lat,
        if (loc != null) 'lon': loc.lng,
      };

      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/ambient/daily-path'),
            headers: ApiConfig.publicHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('⚠️ AmbientService HTTP ${res.statusCode}: ${res.body}');
        }
        return null;
      }

      final json = jsonDecode(res.body);
      if (json is! Map) return null;
      final map = Map<String, dynamic>.from(json);
      if (map['success'] == false) return null;

      final path = DailyPath.fromJson(map);
      await prefs.setString(cacheKey, jsonEncode(path.toJson()));
      return path;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ AmbientService.loadDailyPath: $e');
      return null;
    }
  }
}
