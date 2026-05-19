// PowerSpotsService — Heilige Orte + User-Power-Spots (F3).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class PowerSpot {
  final String id;
  final String userId;
  final String? username;
  final String name;
  final double lat;
  final double lng;
  final String? description;
  final String? energyType;
  final bool isSystem;
  const PowerSpot({
    required this.id,
    required this.userId,
    required this.username,
    required this.name,
    required this.lat,
    required this.lng,
    required this.description,
    required this.energyType,
    required this.isSystem,
  });

  factory PowerSpot.fromJson(Map<String, dynamic> j) => PowerSpot(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        username: j['username'] as String?,
        name: j['name'] as String? ?? '?',
        lat: (j['latitude'] as num).toDouble(),
        lng: (j['longitude'] as num).toDouble(),
        description: j['description'] as String?,
        energyType: j['energy_type'] as String?,
        isSystem: (j['user_id'] as String?) == 'system',
      );
}

class PowerSpotsService {
  PowerSpotsService._();
  static final instance = PowerSpotsService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<List<PowerSpot>> all({int limit = 200}) async {
    try {
      final res = await _s
          .from('user_power_spots')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => PowerSpot.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PowerSpots all: $e');
      return const [];
    }
  }

  Future<PowerSpot?> add({
    required String userId,
    String? username,
    required String name,
    required double lat,
    required double lng,
    String? description,
    String? energyType,
  }) async {
    try {
      final res = await _s
          .from('user_power_spots')
          .insert({
            'user_id': userId,
            'username': username,
            'name': name,
            'latitude': lat,
            'longitude': lng,
            'description': description,
            'energy_type': energyType,
          })
          .select()
          .single();
      return PowerSpot.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PowerSpots add: $e');
      return null;
    }
  }
}
