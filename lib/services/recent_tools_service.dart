// RecentToolsService — merkt sich die zuletzt geoeffneten Spirit-Tools lokal.
//
// Speichert eine geordnete Liste von Tool-IDs (most-recent-first) in
// SharedPreferences. Wird vom Spirit-Tab genutzt, um eine "Zuletzt
// benutzt"-Kategorie zu fuellen, ohne den vorhandenen Tool-Katalog zu
// duplizieren.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class RecentToolsService {
  RecentToolsService._();
  static final instance = RecentToolsService._();

  static const String _key = 'recent_spirit_tools';
  static const int _maxEntries = 12;

  List<String> _recent = [];
  bool _loaded = false;

  /// Recent tool IDs, most-recent-first. Empty until [init] has run.
  List<String> get recent => List.unmodifiable(_recent);

  Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _recent = prefs.getStringList(_key) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RecentToolsService init: $e');
      _recent = [];
    }
    _loaded = true;
  }

  /// Records [toolId] as just used: moves it to the front, dedupes, trims.
  Future<void> record(String toolId) async {
    if (toolId.isEmpty) return;
    if (!_loaded) await init();
    _recent
      ..removeWhere((id) => id == toolId)
      ..insert(0, toolId);
    if (_recent.length > _maxEntries) {
      _recent = _recent.sublist(0, _maxEntries);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _recent);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RecentToolsService record: $e');
    }
  }

  bool isRecent(String toolId) => _recent.contains(toolId);

  Future<void> clear() async {
    _recent = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RecentToolsService clear: $e');
    }
  }
}
