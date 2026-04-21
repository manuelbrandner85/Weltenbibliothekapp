/// Follow-System Service
/// Wraps the `followers` Supabase table (created in migration v41).
/// DB trigger fn_notify_follow() fires automatically on INSERT.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  SupabaseClient get _db => Supabase.instance.client;

  String? get _currentUserId => _db.auth.currentUser?.id;

  /// Returns true if the current user follows [targetUserId].
  Future<bool> isFollowing(String targetUserId) async {
    final me = _currentUserId;
    if (me == null) return false;
    try {
      final res = await _db
          .from('followers')
          .select('id')
          .eq('follower_id', me)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      if (kDebugMode) debugPrint('FollowService.isFollowing error: $e');
      return false;
    }
  }

  /// Follow a user. Returns true on success.
  Future<bool> follow(String targetUserId) async {
    final me = _currentUserId;
    if (me == null || me == targetUserId) return false;
    try {
      await _db.from('followers').insert({
        'follower_id': me,
        'following_id': targetUserId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('FollowService.follow error: $e');
      return false;
    }
  }

  /// Unfollow a user. Returns true on success.
  Future<bool> unfollow(String targetUserId) async {
    final me = _currentUserId;
    if (me == null) return false;
    try {
      await _db
          .from('followers')
          .delete()
          .eq('follower_id', me)
          .eq('following_id', targetUserId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('FollowService.unfollow error: $e');
      return false;
    }
  }

  /// Toggle follow state. Returns new state (true = now following).
  Future<bool> toggleFollow(String targetUserId) async {
    final currently = await isFollowing(targetUserId);
    if (currently) {
      await unfollow(targetUserId);
      return false;
    } else {
      return await follow(targetUserId);
    }
  }

  /// Returns follower count for [userId].
  Future<int> followerCount(String userId) async {
    try {
      final res = await _db
          .from('followers')
          .select('id')
          .eq('following_id', userId)
          .count();
      return res.count;
    } catch (e) {
      return 0;
    }
  }

  /// Returns following count for [userId].
  Future<int> followingCount(String userId) async {
    try {
      final res = await _db
          .from('followers')
          .select('id')
          .eq('follower_id', userId)
          .count();
      return res.count;
    } catch (e) {
      return 0;
    }
  }
}
