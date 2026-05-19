// JournalSearchService — Suche + Tag-Cloud + "Heute vor 1 Jahr" für
// Astral/Dream/Moon-Journals (H3).
//
// Liest aus den lokalen SQLite-Boxen (astral_journal, dream_journal,
// moon_journal). Server-Persist gibt es nicht — Journals bleiben privat.

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'sqlite_storage_service.dart';

enum JournalKind { dream, astral, moon }

class JournalEntry {
  final String id;
  final JournalKind kind;
  final DateTime date;
  final String title;
  final String body;
  final List<String> tags;
  const JournalEntry({
    required this.id,
    required this.kind,
    required this.date,
    required this.title,
    required this.body,
    required this.tags,
  });
}

class JournalSearchService {
  JournalSearchService._();
  static final instance = JournalSearchService._();

  Future<List<JournalEntry>> _read(JournalKind kind) async {
    final box = switch (kind) {
      JournalKind.dream => 'dream_journal',
      JournalKind.astral => 'astral_journal',
      JournalKind.moon => 'moon_journal',
    };
    try {
      final raw = await SqliteStorageService.instance.getAll(box);
      return raw.map((r) {
        final m =
            (r is Map) ? Map<String, dynamic>.from(r) : <String, dynamic>{};
        return JournalEntry(
          id: (m['id'] ?? '').toString(),
          kind: kind,
          date: DateTime.tryParse(
                  m['date']?.toString() ?? m['created_at']?.toString() ?? '') ??
              DateTime.now(),
          title: m['title']?.toString() ?? '',
          body: m['body']?.toString() ?? m['content']?.toString() ?? '',
          tags: (m['tags'] as List?)?.cast<String>() ?? const [],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Journal read $kind: $e');
      return const [];
    }
  }

  Future<List<JournalEntry>> search(String query, {JournalKind? kind}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];
    final entries = <JournalEntry>[];
    for (final k in JournalKind.values) {
      if (kind != null && k != kind) continue;
      entries.addAll(await _read(k));
    }
    return entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.body.toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<Map<String, int>> tagCloud({JournalKind? kind}) async {
    final entries = <JournalEntry>[];
    for (final k in JournalKind.values) {
      if (kind != null && k != kind) continue;
      entries.addAll(await _read(k));
    }
    final counts = <String, int>{};
    for (final e in entries) {
      for (final t in e.tags) {
        final norm = t.toLowerCase().trim();
        if (norm.isEmpty) continue;
        counts[norm] = (counts[norm] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// "Heute vor 1 Jahr"-Erinnerungen: alle Einträge die heute genau X
  /// Jahre alt sind (X = 1, 2, 3, …).
  Future<List<JournalEntry>> onThisDay() async {
    final now = DateTime.now();
    final entries = <JournalEntry>[];
    for (final k in JournalKind.values) {
      entries.addAll(await _read(k));
    }
    return entries.where((e) {
      final years = now.year - e.date.year;
      return years > 0 && e.date.month == now.month && e.date.day == now.day;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
