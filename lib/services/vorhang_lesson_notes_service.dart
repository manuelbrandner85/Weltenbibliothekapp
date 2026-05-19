// VorhangLessonNotesService — Notizen pro Modul (I1).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonNote {
  final String id;
  final String userId;
  final String moduleCode;
  final String body;
  final List<String> tags;
  final DateTime updatedAt;
  const LessonNote({
    required this.id,
    required this.userId,
    required this.moduleCode,
    required this.body,
    required this.tags,
    required this.updatedAt,
  });

  factory LessonNote.fromJson(Map<String, dynamic> j) => LessonNote(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        moduleCode: j['module_code'] as String? ?? '',
        body: j['body'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class VorhangLessonNotesService {
  VorhangLessonNotesService._();
  static final instance = VorhangLessonNotesService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<LessonNote?> getFor(String userId, String moduleCode) async {
    try {
      final res = await _s
          .from('vorhang_lesson_notes')
          .select()
          .eq('user_id', userId)
          .eq('module_code', moduleCode)
          .maybeSingle();
      if (res == null) return null;
      return LessonNote.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LessonNote get: $e');
      return null;
    }
  }

  Future<LessonNote?> save({
    required String userId,
    required String moduleCode,
    required String body,
    List<String> tags = const [],
  }) async {
    try {
      final res = await _s
          .from('vorhang_lesson_notes')
          .upsert({
            'user_id': userId,
            'module_code': moduleCode,
            'body': body,
            'tags': tags,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,module_code')
          .select()
          .single();
      return LessonNote.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LessonNote save: $e');
      return null;
    }
  }

  Future<List<LessonNote>> allFor(String userId) async {
    try {
      final res = await _s
          .from('vorhang_lesson_notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return (res as List)
          .map((r) => LessonNote.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LessonNote all: $e');
      return const [];
    }
  }

  /// Export aller Notizen als Markdown.
  Future<String> exportMarkdown(String userId) async {
    final notes = await allFor(userId);
    if (notes.isEmpty) return '# Vorhang-Notizen\n\n_Noch keine Notizen._';
    final buf = StringBuffer()
      ..writeln('# Vorhang-Notizen')
      ..writeln('')
      ..writeln('_Export: ${DateTime.now().toIso8601String()}_')
      ..writeln('');
    for (final n in notes) {
      buf
        ..writeln('## ${n.moduleCode}')
        ..writeln('')
        ..writeln(n.body)
        ..writeln('');
      if (n.tags.isNotEmpty) {
        buf
          ..writeln('_Tags: ${n.tags.map((t) => "#$t").join(", ")}_')
          ..writeln('');
      }
    }
    return buf.toString();
  }
}
