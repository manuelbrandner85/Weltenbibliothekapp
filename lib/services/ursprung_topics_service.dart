// Ursprung-Topics-Service (R8).
// Liefert dynamische Topics aus 'ursprung_topics' mit lokalem Fallback.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'supabase_service.dart';

class UrsprungTopic {
  final String id;
  final String title;
  final String iconName;
  final String summary;
  final String detailMarkdown;
  final String? sourceLabel;
  final String? sourceUrl;
  final int sortOrder;

  const UrsprungTopic({
    required this.id,
    required this.title,
    required this.iconName,
    required this.summary,
    required this.detailMarkdown,
    this.sourceLabel,
    this.sourceUrl,
    this.sortOrder = 0,
  });

  factory UrsprungTopic.fromJson(Map<String, dynamic> j) => UrsprungTopic(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        iconName: j['icon_name'] as String? ?? 'public',
        summary: j['summary'] as String? ?? '',
        detailMarkdown: j['detail_markdown'] as String? ?? '',
        sourceLabel: j['source_label'] as String?,
        sourceUrl: j['source_url'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );

  IconData get icon {
    switch (iconName) {
      case 'psychology': return Icons.psychology_rounded;
      case 'science': return Icons.science_rounded;
      case 'hexagon': return Icons.hexagon_outlined;
      case 'public': return Icons.public_rounded;
      case 'self_improvement': return Icons.self_improvement_rounded;
      case 'school': return Icons.school_rounded;
      case 'blur_on': return Icons.blur_on_rounded;
      case 'visibility': return Icons.visibility_rounded;
      case 'graphic_eq': return Icons.graphic_eq_rounded;
      case 'account_balance': return Icons.account_balance_rounded;
      default: return Icons.public_rounded;
    }
  }
}

class UrsprungTopicsService {
  UrsprungTopicsService._();
  static final UrsprungTopicsService instance = UrsprungTopicsService._();

  Future<List<UrsprungTopic>> fetch({String? searchQuery}) async {
    try {
      final client = supabase;
      dynamic q = client.from('ursprung_topics').select().eq('is_active', true);
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final s = searchQuery.trim();
        q = q.or('title.ilike.%$s%,summary.ilike.%$s%');
      }
      final res = await q.order('sort_order', ascending: true);
      return (res as List)
          .map((e) =>
              UrsprungTopic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Ursprung-Topics fetch: $e');
      return [];
    }
  }

  /// Verwandte Topics basierend auf gemeinsamen Stichwoertern im Titel.
  Future<List<UrsprungTopic>> related(UrsprungTopic topic) async {
    try {
      final client = supabase;
      // Einfache Heuristik: Suche nach 2-3 wichtigsten Woertern aus dem Titel.
      final words = topic.title
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 4)
          .take(2)
          .toList();
      if (words.isEmpty) return [];
      final ors = words
          .map((w) => 'title.ilike.%$w%,summary.ilike.%$w%')
          .join(',');
      final res = await client
          .from('ursprung_topics')
          .select()
          .eq('is_active', true)
          .neq('id', topic.id)
          .or(ors)
          .limit(3);
      return (res as List)
          .map((e) =>
              UrsprungTopic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
