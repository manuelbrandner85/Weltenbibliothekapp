// Archive video service — reads from archive_videos Supabase table.
// Only status='confirmed' rows are visible (enforced by RLS + explicit filter).

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchiveVideo {
  final String id;
  final String youtubeVideoId;
  final String title;
  final String rawTitle;
  final String? thumbnailUrl;
  final String? category;
  final List<String> worlds;
  final DateTime createdAt;

  const ArchiveVideo({
    required this.id,
    required this.youtubeVideoId,
    required this.title,
    required this.rawTitle,
    this.thumbnailUrl,
    this.category,
    required this.worlds,
    required this.createdAt,
  });

  String get effectiveThumbnail =>
      thumbnailUrl?.isNotEmpty == true
          ? thumbnailUrl!
          : 'https://img.youtube.com/vi/$youtubeVideoId/mqdefault.jpg';

  factory ArchiveVideo.fromJson(Map<String, dynamic> j) {
    final rawWorlds = j['worlds'];
    final List<String> worlds = rawWorlds is List
        ? rawWorlds.map((e) => e.toString()).toList()
        : <String>[];
    return ArchiveVideo(
      id: j['id']?.toString() ?? '',
      youtubeVideoId: j['youtube_video_id']?.toString() ?? '',
      title: j['youtube_title']?.toString() ??
          j['raw_title']?.toString() ??
          '',
      rawTitle: j['raw_title']?.toString() ?? '',
      thumbnailUrl: j['thumbnail_url']?.toString(),
      category: j['category']?.toString(),
      worlds: worlds,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime(2024)
          : DateTime(2024),
    );
  }
}

class ArchiveVideoService {
  ArchiveVideoService._();
  static final ArchiveVideoService instance = ArchiveVideoService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<ArchiveVideo>> fetchLatest({
    required String world,
    int limit = 8,
  }) async {
    try {
      final res = await _db
          .from('archive_videos')
          .select()
          .eq('status', 'confirmed')
          .contains('worlds', [world])
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => ArchiveVideo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('ArchiveVideoService.fetchLatest: $e');
      return [];
    }
  }

  /// C3: Videos, die einem konkreten Lern-Modul zugeordnet sind.
  Future<List<ArchiveVideo>> fetchByModule({
    required String world,
    required String moduleCode,
  }) async {
    try {
      final res = await _db
          .from('archive_videos')
          .select()
          .eq('status', 'confirmed')
          .eq('module_world', world)
          .eq('module_code', moduleCode.toUpperCase())
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => ArchiveVideo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('ArchiveVideoService.fetchByModule: $e');
      return [];
    }
  }

  Future<List<ArchiveVideo>> fetchByCategory({
    required String world,
    required String category,
  }) async {
    try {
      final res = await _db
          .from('archive_videos')
          .select()
          .eq('status', 'confirmed')
          .contains('worlds', [world])
          .eq('category', category)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => ArchiveVideo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('ArchiveVideoService.fetchByCategory: $e');
      return [];
    }
  }

  Future<List<ArchiveVideo>> search({
    required String world,
    required String query,
  }) async {
    if (query.trim().isEmpty) return fetchLatest(world: world, limit: 50);
    try {
      final q = query.trim().toLowerCase();
      final res = await _db
          .from('archive_videos')
          .select()
          .eq('status', 'confirmed')
          .contains('worlds', [world])
          .or('youtube_title.ilike.%$q%,raw_title.ilike.%$q%')
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => ArchiveVideo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('ArchiveVideoService.search: $e');
      return [];
    }
  }

  Future<List<String>> fetchCategories(String world) async {
    try {
      final res = await _db
          .from('archive_videos')
          .select('category')
          .eq('status', 'confirmed')
          .contains('worlds', [world])
          .not('category', 'is', null);
      final cats = (res as List)
          .map((e) => e['category']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return cats;
    } catch (e) {
      if (kDebugMode) debugPrint('ArchiveVideoService.fetchCategories: $e');
      return [];
    }
  }
}
