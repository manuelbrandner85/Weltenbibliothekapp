// BookmarkCollectionService — Ordner-Struktur für Bookmarks (L5).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarkCollection {
  final String id;
  final String userId;
  final String name;
  final String? icon;
  final String? color;
  final int orderIdx;
  const BookmarkCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.orderIdx,
  });

  factory BookmarkCollection.fromJson(Map<String, dynamic> j) =>
      BookmarkCollection(
        id: j['id'] as String,
        userId: j['user_id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        icon: j['icon'] as String?,
        color: j['color'] as String?,
        orderIdx: (j['order_idx'] as int?) ?? 0,
      );
}

class BookmarkCollectionService {
  BookmarkCollectionService._();
  static final instance = BookmarkCollectionService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<List<BookmarkCollection>> listFor(String userId) async {
    try {
      final res = await _s
          .from('bookmark_collections')
          .select()
          .eq('user_id', userId)
          .order('order_idx', ascending: true);
      return (res as List)
          .map((r) =>
              BookmarkCollection.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Coll list: $e');
      return const [];
    }
  }

  Future<BookmarkCollection?> create({
    required String userId,
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      final existing = await listFor(userId);
      final res = await _s
          .from('bookmark_collections')
          .insert({
            'user_id': userId,
            'name': name,
            'icon': icon,
            'color': color,
            'order_idx': existing.length,
          })
          .select()
          .single();
      return BookmarkCollection.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Coll create: $e');
      return null;
    }
  }

  Future<bool> addBookmark({
    required String collectionId,
    required String bookmarkId,
  }) async {
    try {
      await _s.from('bookmark_collection_items').upsert({
        'collection_id': collectionId,
        'bookmark_id': bookmarkId,
      }, onConflict: 'collection_id,bookmark_id');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Coll add: $e');
      return false;
    }
  }

  Future<bool> removeBookmark({
    required String collectionId,
    required String bookmarkId,
  }) async {
    try {
      await _s
          .from('bookmark_collection_items')
          .delete()
          .eq('collection_id', collectionId)
          .eq('bookmark_id', bookmarkId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Coll remove: $e');
      return false;
    }
  }

  Future<List<String>> bookmarksOf(String collectionId) async {
    try {
      final res = await _s
          .from('bookmark_collection_items')
          .select('bookmark_id')
          .eq('collection_id', collectionId);
      return (res as List)
          .map((r) => (r as Map)['bookmark_id'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Coll items: $e');
      return const [];
    }
  }
}
