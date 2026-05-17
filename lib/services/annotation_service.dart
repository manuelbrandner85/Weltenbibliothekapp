// AnnotationService — Highlights + Notizen im Knowledge-Reader (L3).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class Annotation {
  final String id;
  final String userId;
  final String resourceType;
  final String resourceId;
  final String highlight;
  final String? note;
  final String color;
  final Map<String, dynamic>? position;
  final DateTime createdAt;
  const Annotation({
    required this.id,
    required this.userId,
    required this.resourceType,
    required this.resourceId,
    required this.highlight,
    required this.note,
    required this.color,
    required this.position,
    required this.createdAt,
  });

  factory Annotation.fromJson(Map<String, dynamic> j) => Annotation(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        resourceType: j['resource_type'] as String? ?? '',
        resourceId: j['resource_id'] as String? ?? '',
        highlight: j['highlight'] as String? ?? '',
        note: j['note'] as String?,
        color: j['color'] as String? ?? 'yellow',
        position: j['position'] is Map ? Map<String, dynamic>.from(j['position'] as Map) : null,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class AnnotationService {
  AnnotationService._();
  static final instance = AnnotationService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<List<Annotation>> forResource({
    required String userId,
    required String resourceType,
    required String resourceId,
  }) async {
    try {
      final res = await _s
          .from('user_annotations')
          .select()
          .eq('user_id', userId)
          .eq('resource_type', resourceType)
          .eq('resource_id', resourceId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((r) => Annotation.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Annotation list: $e');
      return const [];
    }
  }

  Future<Annotation?> add({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String highlight,
    String? note,
    String color = 'yellow',
    Map<String, dynamic>? position,
  }) async {
    try {
      final res = await _s.from('user_annotations').insert({
        'user_id': userId,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'highlight': highlight,
        'note': note,
        'color': color,
        'position': position,
      }).select().single();
      return Annotation.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Annotation add: $e');
      return null;
    }
  }

  Future<bool> updateNote(String id, String note) async {
    try {
      await _s.from('user_annotations').update({'note': note}).eq('id', id);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Annotation update: $e');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _s.from('user_annotations').delete().eq('id', id);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Annotation delete: $e');
      return false;
    }
  }
}
