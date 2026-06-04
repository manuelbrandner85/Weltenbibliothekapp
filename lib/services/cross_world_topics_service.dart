// Erweiterung 2 "Vier Linsen": one topic viewed through all four worlds.
// Reads the public cross_world_topics table with a local fallback.

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// A cross-world topic with one perspective ("lens") per world.
/// Plain Dart class (NO Dart 3 record types).
class CrossWorldTopic {
  final String id;
  final String slug;
  final String title;
  final String? subtitle;
  final String? emoji;
  final int sortOrder;

  /// Per-world lens text. Keys: 'materie','energie','vorhang','ursprung'.
  final Map<String, String> lenses;

  const CrossWorldTopic({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle,
    this.emoji,
    this.sortOrder = 0,
    this.lenses = const {},
  });

  factory CrossWorldTopic.fromJson(Map<String, dynamic> j) {
    final lenses = <String, String>{};
    void put(String key, String column) {
      final v = j[column];
      if (v != null && v.toString().isNotEmpty) lenses[key] = v.toString();
    }

    put('materie', 'materie_ref');
    put('energie', 'energie_ref');
    put('vorhang', 'vorhang_ref');
    put('ursprung', 'ursprung_ref');

    return CrossWorldTopic(
      id: j['id'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
      title: j['title'] as String? ?? '',
      subtitle: j['subtitle'] as String?,
      emoji: j['emoji'] as String?,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      lenses: lenses,
    );
  }
}

/// Singleton service: Supabase-first with a resilient local fallback.
/// Read-only on the client; content is curated by content_editor+.
class CrossWorldTopicsService {
  CrossWorldTopicsService._();
  static final CrossWorldTopicsService instance = CrossWorldTopicsService._();

  Future<List<CrossWorldTopic>> fetch() async {
    try {
      final res = await supabase
          .from('cross_world_topics')
          .select()
          .order('sort_order', ascending: true);
      final list = (res as List)
          .map((e) =>
              CrossWorldTopic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return list.isEmpty ? _fallback : list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Cross-World-Topics fetch: $e');
      return _fallback;
    }
  }

  /// Minimal offline fallback (mirrors the v122 seed head).
  static const List<CrossWorldTopic> _fallback = [
    CrossWorldTopic(
      id: 'fallback-mond',
      slug: 'mond',
      title: 'Der Mond',
      subtitle: 'Ein Himmelskoerper -- vier Perspektiven',
      emoji: '🌙',
      sortOrder: 10,
      lenses: {
        'materie': 'Apollo-Missionen und offene Fragen zur Mondlandung.',
        'energie': 'Mondkalender, Mondphasen und ihr Einfluss auf Rhythmen.',
        'vorhang': 'Verborgene Mond-Symbolik in Logos, Wappen und Kulten.',
        'ursprung': 'Schoepfungsmythen: der Mond als Urgottheit und Zeitgeber.',
      },
    ),
  ];
}
