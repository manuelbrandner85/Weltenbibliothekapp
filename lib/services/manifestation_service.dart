// ManifestationService — Reality-Architect Manifestations-Tracker (J4).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class ManifestationGoal {
  final String id;
  final String userId;
  final String? username;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final bool reminder30d;
  final bool reminder90d;
  final DateTime? reviewedAt;
  final bool? manifested;
  final String? notes;
  final DateTime createdAt;
  const ManifestationGoal({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.reminder30d,
    required this.reminder90d,
    required this.reviewedAt,
    required this.manifested,
    required this.notes,
    required this.createdAt,
  });

  factory ManifestationGoal.fromJson(Map<String, dynamic> j) => ManifestationGoal(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        username: j['username'] as String?,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        targetDate: j['target_date'] != null
            ? DateTime.tryParse(j['target_date'] as String)
            : null,
        reminder30d: j['reminder_30d'] as bool? ?? true,
        reminder90d: j['reminder_90d'] as bool? ?? true,
        reviewedAt: j['reviewed_at'] != null
            ? DateTime.tryParse(j['reviewed_at'] as String)
            : null,
        manifested: j['manifested'] as bool?,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ManifestationService {
  ManifestationService._();
  static final instance = ManifestationService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<ManifestationGoal?> create({
    required String userId,
    String? username,
    required String title,
    String? description,
    DateTime? targetDate,
  }) async {
    try {
      final res = await _s.from('manifestation_goals').insert({
        'user_id': userId,
        'username': username,
        'title': title,
        'description': description,
        'target_date': targetDate?.toIso8601String().substring(0, 10),
      }).select().single();
      return ManifestationGoal.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Manifest create: $e');
      return null;
    }
  }

  Future<List<ManifestationGoal>> listFor(String userId) async {
    try {
      final res = await _s
          .from('manifestation_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((r) => ManifestationGoal.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Manifest list: $e');
      return const [];
    }
  }

  Future<bool> review({
    required String goalId,
    required bool manifested,
    String? notes,
  }) async {
    try {
      await _s.from('manifestation_goals').update({
        'manifested': manifested,
        'notes': notes,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', goalId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Manifest review: $e');
      return false;
    }
  }

  /// Liefert Goals deren Reminder fällig ist (30d oder 90d) und noch
  /// nicht reviewt wurden.
  Future<List<ManifestationGoal>> dueForReview(String userId) async {
    final all = await listFor(userId);
    final now = DateTime.now();
    return all.where((g) {
      if (g.reviewedAt != null) return false;
      final days = now.difference(g.createdAt).inDays;
      if (g.reminder30d && days >= 30 && days < 89) return true;
      if (g.reminder90d && days >= 90) return true;
      return false;
    }).toList();
  }
}
