// OsintHistoryService — pro OSINT-Tool letzte N Abfragen lokal speichern (D1).
//
// SharedPrefs-Storage; Pro Tool ein eigener Key. Anti-Duplikat (gleiche
// Query überschreibt Timestamp). Star/Pin via separate Liste.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class OsintHistoryEntry {
  final String query;
  final DateTime timestamp;
  final bool starred;
  final Map<String, dynamic> resultPreview;
  const OsintHistoryEntry({
    required this.query,
    required this.timestamp,
    this.starred = false,
    this.resultPreview = const {},
  });

  Map<String, dynamic> toJson() => {
        'q': query,
        't': timestamp.toIso8601String(),
        's': starred,
        'r': resultPreview,
      };
  factory OsintHistoryEntry.fromJson(Map<String, dynamic> j) =>
      OsintHistoryEntry(
        query: j['q'] as String? ?? '',
        timestamp: DateTime.tryParse(j['t'] as String? ?? '') ?? DateTime.now(),
        starred: j['s'] as bool? ?? false,
        resultPreview: Map<String, dynamic>.from(j['r'] as Map? ?? {}),
      );
}

class OsintHistoryService {
  OsintHistoryService._();
  static final instance = OsintHistoryService._();

  static const _maxPerTool = 20;
  String _key(String tool) => 'osint_history_$tool';

  Future<List<OsintHistoryEntry>> list(String tool) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(tool));
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              OsintHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) {
          // Starred zuerst, dann neueste
          if (a.starred != b.starred) return a.starred ? -1 : 1;
          return b.timestamp.compareTo(a.timestamp);
        });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OsintHistory list: $e');
      return const [];
    }
  }

  Future<void> add(
    String tool,
    String query, {
    Map<String, dynamic>? resultPreview,
  }) async {
    try {
      final existing = await list(tool);
      // gleiche Query → entfernen, neu vorne anfügen
      final filtered = existing.where((e) => e.query != query).toList();
      filtered.insert(
        0,
        OsintHistoryEntry(
          query: query,
          timestamp: DateTime.now(),
          resultPreview: resultPreview ?? const {},
        ),
      );
      final trimmed = filtered.take(_maxPerTool).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(tool),
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OsintHistory add: $e');
    }
  }

  Future<void> toggleStar(String tool, String query) async {
    try {
      final existing = await list(tool);
      final updated = existing
          .map((e) => e.query == query
              ? OsintHistoryEntry(
                  query: e.query,
                  timestamp: e.timestamp,
                  starred: !e.starred,
                  resultPreview: e.resultPreview,
                )
              : e)
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(tool),
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OsintHistory star: $e');
    }
  }

  Future<void> clear(String tool) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(tool));
  }
}
