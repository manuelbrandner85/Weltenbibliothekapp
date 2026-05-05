/// 📌 SAVED-THREADS-SERVICE — speichert Recherche-Pfade in Supabase.
///
/// Tabellen (v47):
///   • saved_threads          — User-Threads
///   • thread_annotations     — Community-Hinweise pro Topic
///   • thread_annotation_votes — Up/Downvotes
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedThread {
  final String id;
  final String userId;
  final String topic;
  final List<String> path;
  final String? notes;
  final bool isPublic;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedThread({
    required this.id,
    required this.userId,
    required this.topic,
    required this.path,
    this.notes,
    this.isPublic = false,
    this.shareToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedThread.fromJson(Map<String, dynamic> j) => SavedThread(
        id: j['id'].toString(),
        userId: j['user_id'].toString(),
        topic: j['topic']?.toString() ?? '',
        path: (j['path'] as List?)?.map((e) => e.toString()).toList() ?? [],
        notes: j['notes']?.toString(),
        isPublic: j['is_public'] == true,
        shareToken: j['share_token']?.toString(),
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(j['updated_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ThreadAnnotation {
  final String id;
  final String? userId;
  final bool isAnonymous;
  final String body;
  final String? sourceUrl;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;

  ThreadAnnotation({
    required this.id,
    this.userId,
    required this.isAnonymous,
    required this.body,
    this.sourceUrl,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
  });

  int get score => upvotes - downvotes;

  factory ThreadAnnotation.fromJson(Map<String, dynamic> j) => ThreadAnnotation(
        id: j['id'].toString(),
        userId: j['user_id']?.toString(),
        isAnonymous: j['is_anonymous'] == true,
        body: j['body']?.toString() ?? '',
        sourceUrl: j['source_url']?.toString(),
        upvotes: (j['upvotes'] as int?) ?? 0,
        downvotes: (j['downvotes'] as int?) ?? 0,
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class SavedThreadsService {
  static final SavedThreadsService instance = SavedThreadsService._();
  SavedThreadsService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Saved Threads ──────────────────────────────────────────

  Future<List<SavedThread>> listMyThreads() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return [];
      final data = await _client
          .from('saved_threads')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      return (data as List)
          .map((e) => SavedThread.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('listMyThreads-Error: $e');
      return [];
    }
  }

  Future<SavedThread?> saveThread({
    required String topic,
    required List<String> path,
    String? notes,
    bool isPublic = false,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;
      final shareToken = isPublic ? _genToken() : null;
      final inserted = await _client
          .from('saved_threads')
          .insert({
            'user_id': uid,
            'topic': topic,
            'path': path,
            'notes': notes,
            'is_public': isPublic,
            'share_token': shareToken,
          })
          .select()
          .single();
      return SavedThread.fromJson(inserted);
    } catch (e) {
      debugPrint('saveThread-Error: $e');
      return null;
    }
  }

  Future<bool> deleteThread(String id) async {
    try {
      await _client.from('saved_threads').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('deleteThread-Error: $e');
      return false;
    }
  }

  Future<SavedThread?> loadByShareToken(String token) async {
    try {
      final data = await _client
          .from('saved_threads')
          .select()
          .eq('share_token', token)
          .maybeSingle();
      if (data == null) return null;
      return SavedThread.fromJson(data);
    } catch (e) {
      debugPrint('loadByShareToken-Error: $e');
      return null;
    }
  }

  // ── Community Annotations ──────────────────────────────────

  Future<List<ThreadAnnotation>> listAnnotations(String topic) async {
    try {
      final data = await _client
          .from('thread_annotations')
          .select()
          .ilike('topic', topic)
          .eq('flagged', false)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => ThreadAnnotation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('listAnnotations-Error: $e');
      return [];
    }
  }

  Future<ThreadAnnotation?> addAnnotation({
    required String topic,
    required String body,
    String? sourceUrl,
    bool isAnonymous = false,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;
      final inserted = await _client
          .from('thread_annotations')
          .insert({
            'topic': topic.toLowerCase().trim(),
            'user_id': isAnonymous ? null : uid,
            'is_anonymous': isAnonymous,
            'body': body,
            'source_url': sourceUrl,
          })
          .select()
          .single();
      return ThreadAnnotation.fromJson(inserted);
    } catch (e) {
      debugPrint('addAnnotation-Error: $e');
      return null;
    }
  }

  Future<bool> voteAnnotation(String annotationId, int vote) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return false;
      if (vote == 0) {
        await _client
            .from('thread_annotation_votes')
            .delete()
            .eq('annotation_id', annotationId)
            .eq('user_id', uid);
      } else {
        await _client.from('thread_annotation_votes').upsert({
          'annotation_id': annotationId,
          'user_id': uid,
          'vote': vote,
        });
      }
      return true;
    } catch (e) {
      debugPrint('voteAnnotation-Error: $e');
      return false;
    }
  }

  Future<int> annotationsCount(String topic) async {
    try {
      final data = await _client
          .from('thread_annotations')
          .count(CountOption.exact)
          .eq('flagged', false);
      return data;
    } catch (e) {
      return 0;
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  String _genToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
