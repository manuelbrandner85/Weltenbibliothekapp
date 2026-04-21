/// World Subscription Service
/// Manages opt-in article alerts per world (migration v41: world_subscriptions table).
/// DB trigger fn_notify_new_article() fires when is_published flips to true.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorldSubscriptionService {
  static final WorldSubscriptionService _instance =
      WorldSubscriptionService._internal();
  factory WorldSubscriptionService() => _instance;
  WorldSubscriptionService._internal();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  /// Returns true if the current user is subscribed to [world] article alerts.
  Future<bool> isSubscribed(String world) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final res = await _db
          .from('world_subscriptions')
          .select('id')
          .eq('user_id', uid)
          .eq('world', world)
          .maybeSingle();
      return res != null;
    } catch (e) {
      if (kDebugMode) debugPrint('WorldSubscriptionService.isSubscribed error: $e');
      return false;
    }
  }

  /// Subscribe to article alerts for [world]. No-op if already subscribed.
  Future<bool> subscribe(String world) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db.from('world_subscriptions').upsert(
        {'user_id': uid, 'world': world},
        onConflict: 'user_id,world',
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('WorldSubscriptionService.subscribe error: $e');
      return false;
    }
  }

  /// Unsubscribe from article alerts for [world].
  Future<bool> unsubscribe(String world) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db
          .from('world_subscriptions')
          .delete()
          .eq('user_id', uid)
          .eq('world', world);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('WorldSubscriptionService.unsubscribe error: $e');
      return false;
    }
  }

  /// Toggle subscription for [world]. Returns new state (true = subscribed).
  Future<bool> toggle(String world) async {
    final subscribed = await isSubscribed(world);
    if (subscribed) {
      await unsubscribe(world);
      return false;
    } else {
      return await subscribe(world);
    }
  }
}
