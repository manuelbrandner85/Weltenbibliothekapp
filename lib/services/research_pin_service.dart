// ResearchPinService — CRUD für user_research_pins (B2).
//
// Schreibt/liest direkt gegen Supabase via supabase-flutter. RLS lässt
// anon-Inserts zu (Auth-Refactor ändert das später).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class ResearchPin {
  final String id;
  final String userId;
  final String? username;
  final String world;
  final double lat;
  final double lng;
  final String title;
  final String? description;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;

  const ResearchPin({
    required this.id,
    required this.userId,
    required this.username,
    required this.world,
    required this.lat,
    required this.lng,
    required this.title,
    required this.description,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
  });

  factory ResearchPin.fromJson(Map<String, dynamic> j) => ResearchPin(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        username: j['username'] as String?,
        world: j['world'] as String? ?? 'materie',
        lat: (j['latitude'] as num).toDouble(),
        lng: (j['longitude'] as num).toDouble(),
        title: j['title'] as String? ?? '?',
        description: j['description'] as String?,
        upvotes: (j['upvotes'] as int?) ?? 0,
        downvotes: (j['downvotes'] as int?) ?? 0,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  int get score => upvotes - downvotes;
}

class ResearchPinService {
  ResearchPinService._();
  static final instance = ResearchPinService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<List<ResearchPin>> list(String world, {int limit = 100}) async {
    try {
      final res = await _s
          .from('user_research_pins')
          .select()
          .eq('world', world)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => ResearchPin.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ResearchPin list: $e');
      return const [];
    }
  }

  Future<ResearchPin?> add({
    required String world,
    required String userId,
    String? username,
    required double lat,
    required double lng,
    required String title,
    String? description,
  }) async {
    try {
      final res = await _s.from('user_research_pins').insert({
        'world': world,
        'user_id': userId,
        'username': username,
        'latitude': lat,
        'longitude': lng,
        'title': title,
        'description': description,
      }).select().single();
      return ResearchPin.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ResearchPin add: $e');
      return null;
    }
  }

  Future<bool> vote({
    required String pinId,
    required String userId,
    required int direction, // +1 oder -1
  }) async {
    try {
      // Upsert vote — pkey (pin_id, user_id) sorgt für Wechsel.
      await _s.from('user_research_pin_votes').upsert({
        'pin_id': pinId,
        'user_id': userId,
        'vote': direction,
      }, onConflict: 'pin_id,user_id');

      // Aggregat-Sync — selektiver +1/-1 ist racy, daher Re-Count:
      final votes = await _s
          .from('user_research_pin_votes')
          .select('vote')
          .eq('pin_id', pinId);
      final up = (votes as List).where((v) => (v as Map)['vote'] == 1).length;
      final down = votes.where((v) => (v as Map)['vote'] == -1).length;
      await _s.from('user_research_pins').update({
        'upvotes': up,
        'downvotes': down,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pinId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ResearchPin vote: $e');
      return false;
    }
  }
}
