import 'package:supabase_flutter/supabase_flutter.dart';

/// Matches free-text dream descriptions against the dream_symbols keyword index.
///
/// Symbols are loaded once and cached for the app session.
/// Call [preload] at app start (or lazily on first use).
class DreamSymbolMatcher {
  DreamSymbolMatcher._();
  static final DreamSymbolMatcher instance = DreamSymbolMatcher._();

  // Cache: symbol_key → {keywords, symbol_name, emoji}
  List<_SymbolEntry> _entries = [];
  bool _loaded = false;

  final _db = Supabase.instance.client;

  Future<void> preload() async {
    if (_loaded) return;
    try {
      final rows = await _db
          .from('dream_symbols')
          .select('symbol_key, symbol_name, emoji, keywords');
      _entries = (rows as List).map((r) {
        final kws = (r['keywords'] as List?)?.cast<String>() ?? [];
        return _SymbolEntry(
          key: r['symbol_key'] as String,
          name: r['symbol_name'] as String,
          emoji: r['emoji'] as String? ?? '🔮',
          keywords: kws.map((k) => k.toLowerCase()).toList(),
        );
      }).toList();
      _loaded = true;
    } catch (_) {
      // Fail silently — tags stay empty if DB unreachable
    }
  }

  /// Returns list of [symbol_key]s found in [text] (deduplicated, stable order).
  List<String> match(String text) {
    if (!_loaded || text.isEmpty) return [];
    final lower = _normalize(text);
    final found = <String>[];
    for (final entry in _entries) {
      for (final kw in entry.keywords) {
        if (lower.contains(kw)) {
          found.add(entry.key);
          break;
        }
      }
    }
    return found;
  }

  /// Returns full symbol metadata for a set of keys (for detail display).
  Future<List<Map<String, dynamic>>> symbolsForKeys(
      List<String> keys) async {
    if (keys.isEmpty) return [];
    try {
      final rows = await _db
          .from('dream_symbols')
          .select('symbol_key, symbol_name, emoji, meanings')
          .inFilter('symbol_key', keys);
      // Preserve input order
      final byKey = {
        for (final r in (rows as List)) r['symbol_key'] as String: r
      };
      return keys
          .where(byKey.containsKey)
          .map((k) => Map<String, dynamic>.from(byKey[k]!))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Normalise German text for keyword matching.
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^\w\s]'), ' ');
  }
}

class _SymbolEntry {
  final String key;
  final String name;
  final String emoji;
  final List<String> keywords;
  const _SymbolEntry(
      {required this.key,
      required this.name,
      required this.emoji,
      required this.keywords});
}
