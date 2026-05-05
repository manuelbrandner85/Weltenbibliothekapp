/// Lokaler Recherche-Verlauf — gespeichert in SharedPreferences.
library;

import 'package:shared_preferences/shared_preferences.dart';

class KbHistoryService {
  static const _key = 'kb_search_history';
  static const _max = 12;

  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addTopic(String topic) async {
    final t = topic.trim();
    if (t.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(prefs.getStringList(_key) ?? []);
    list.remove(t);
    list.insert(0, t);
    if (list.length > _max) list.removeRange(_max, list.length);
    await prefs.setStringList(_key, list);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
