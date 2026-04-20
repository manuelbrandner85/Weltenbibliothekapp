import 'package:flutter/foundation.dart';
import 'sqlite_storage_service.dart';
import 'dart:async';
import '../models/knowledge_extended_models.dart';
import '../data/materie_knowledge_data.dart';
import '../data/energie_knowledge_data.dart';
import '../data/materie_knowledge_complete.dart';
import '../data/energie_knowledge_complete.dart';

/// ============================================
/// UNIFIED KNOWLEDGE SERVICE
/// Offline-First mit allen Features:
/// - Hive Local Storage
/// - Favoriten System
/// - Notizen
/// - Lesefortschritt
/// - Echtzeit-Sync (optional)
/// - KI-Empfehlungen
/// ============================================

class UnifiedKnowledgeService {
  static final UnifiedKnowledgeService _instance = UnifiedKnowledgeService._internal();
  factory UnifiedKnowledgeService() => _instance;
  UnifiedKnowledgeService._internal();

  // Hive Box Names
  static const String _knowledgeBox = 'knowledge_entries';
  static const String _favoritesBox = 'knowledge_favorites';
  static const String _notesBox = 'knowledge_notes';
  static const String _progressBox = 'reading_progress';

  bool _initialized = false;
  final StreamController<List<KnowledgeEntry>> _knowledgeStreamController = 
      StreamController<List<KnowledgeEntry>>.broadcast();

  /// INITIALIZATION
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Load initial data if empty
      await _loadInitialData();

      _initialized = true;
      debugPrint('✅ UnifiedKnowledgeService initialized');
    } catch (e) {
      debugPrint('❌ UnifiedKnowledgeService init error: $e');
    }
  }

  /// LOAD INITIAL DATA (from data files)
  Future<void> _loadInitialData() async {
    final db = SqliteStorageService.instance;

    // Only load if box is empty
    if (await db.count(_knowledgeBox) == 0) {
      debugPrint('📚 Loading initial knowledge data (100 entries)...');

      for (var entry in materieKnowledgeDatabase) {
        await db.put(_knowledgeBox, entry.id, entry.toJson());
      }
      for (var entry in materieKnowledgeComplete) {
        await db.put(_knowledgeBox, entry.id, entry.toJson());
      }
      for (var entry in energieKnowledgeDatabase) {
        await db.put(_knowledgeBox, entry.id, entry.toJson());
      }
      for (var entry in energieKnowledgeComplete) {
        await db.put(_knowledgeBox, entry.id, entry.toJson());
      }

      debugPrint('✅ Loaded ${await db.count(_knowledgeBox)} knowledge entries');
    }
  }

  // ==========================================
  // KNOWLEDGE ENTRY METHODS
  // ==========================================

  /// Get all entries (optionally filtered by world)
  Future<List<KnowledgeEntry>> getAllEntries({String? world}) async {
    await init();

    try {
      final db = SqliteStorageService.instance;
      final entries = db.getAllSync(_knowledgeBox)
          .map((e) => KnowledgeEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (world != null) {
        return entries.where((e) => e.world == world).toList();
      }

      return entries;
    } catch (e) {
      debugPrint('❌ getAllEntries error: $e');
      return [];
    }
  }

  /// Get entry by ID
  Future<KnowledgeEntry?> getEntry(String id) async {
    await init();

    try {
      final data = SqliteStorageService.instance.getSync(_knowledgeBox, id);

      if (data != null) {
        return KnowledgeEntry.fromJson(Map<String, dynamic>.from(data as Map));
      }

      return null;
    } catch (e) {
      debugPrint('❌ getEntry error: $e');
      return null;
    }
  }

  /// Get entries by category
  Future<List<KnowledgeEntry>> getByCategory(String world, String category) async {
    final entries = await getAllEntries(world: world);
    return entries.where((e) => e.category == category).toList();
  }

  /// Get entries by type
  Future<List<KnowledgeEntry>> getByType(String world, String type) async {
    final entries = await getAllEntries(world: world);
    return entries.where((e) => e.type == type).toList();
  }

  /// Search entries
  Future<List<KnowledgeEntry>> search(String query, {String? world}) async {
    final entries = await getAllEntries(world: world);
    final lowerQuery = query.toLowerCase();
    
    return entries.where((entry) {
      return entry.title.toLowerCase().contains(lowerQuery) ||
             entry.description.toLowerCase().contains(lowerQuery) ||
             entry.fullContent.toLowerCase().contains(lowerQuery) ||
             entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Increment view count
  Future<void> incrementViewCount(String id) async {
    await init();

    try {
      final entry = await getEntry(id);
      if (entry != null) {
        final updated = entry.copyWith(viewCount: entry.viewCount + 1);
        await SqliteStorageService.instance.put(_knowledgeBox, id, updated.toJson());
      }
    } catch (e) {
      debugPrint('❌ incrementViewCount error: $e');
    }
  }

  // ==========================================
  // FAVORITES SYSTEM
  // ==========================================

  /// Add to favorites
  Future<void> addFavorite(String knowledgeId, {String? notes}) async {
    await init();

    try {
      final favorite = FavoriteEntry(
        knowledgeId: knowledgeId,
        addedAt: DateTime.now(),
        notes: notes,
      );
      await SqliteStorageService.instance.put(_favoritesBox, knowledgeId, favorite.toJson());
      debugPrint('⭐ Added to favorites: $knowledgeId');
    } catch (e) {
      debugPrint('❌ addFavorite error: $e');
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(String knowledgeId) async {
    await init();

    try {
      await SqliteStorageService.instance.delete(_favoritesBox, knowledgeId);
      debugPrint('✅ Removed from favorites: $knowledgeId');
    } catch (e) {
      debugPrint('❌ removeFavorite error: $e');
    }
  }

  /// Check if entry is favorite
  Future<bool> isFavorite(String knowledgeId) async {
    await init();

    try {
      return SqliteStorageService.instance.containsKeySync(_favoritesBox, knowledgeId);
    } catch (e) {
      debugPrint('❌ isFavorite error: $e');
      return false;
    }
  }

  /// Get all favorites
  Future<List<KnowledgeEntry>> getFavorites({String? world}) async {
    await init();

    try {
      final db = SqliteStorageService.instance;
      final favoriteIds = await db.getKeys(_favoritesBox);

      final List<KnowledgeEntry> favorites = [];
      for (var id in favoriteIds) {
        final entry = await getEntry(id);
        if (entry != null && (world == null || entry.world == world)) {
          favorites.add(entry);
        }
      }

      // Sort by added date (most recent first)
      favorites.sort((a, b) {
        final favAData = db.getSync(_favoritesBox, a.id);
        final favBData = db.getSync(_favoritesBox, b.id);
        final favA = FavoriteEntry.fromJson(Map<String, dynamic>.from(favAData as Map));
        final favB = FavoriteEntry.fromJson(Map<String, dynamic>.from(favBData as Map));
        return favB.addedAt.compareTo(favA.addedAt);
      });

      return favorites;
    } catch (e) {
      debugPrint('❌ getFavorites error: $e');
      return [];
    }
  }

  // ==========================================
  // NOTES SYSTEM
  // ==========================================

  /// Add/Update note
  Future<void> saveNote(String knowledgeId, String content, {List<String>? tags}) async {
    await init();

    try {
      final db = SqliteStorageService.instance;
      final existingNoteData = db.getSync(_notesBox, knowledgeId);

      KnowledgeNote note;
      if (existingNoteData != null) {
        final existingNote = KnowledgeNote.fromJson(Map<String, dynamic>.from(existingNoteData as Map));
        note = KnowledgeNote(
          id: existingNote.id,
          knowledgeId: knowledgeId,
          content: content,
          createdAt: existingNote.createdAt,
          updatedAt: DateTime.now(),
          tags: tags ?? existingNote.tags,
        );
      } else {
        note = KnowledgeNote(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          knowledgeId: knowledgeId,
          content: content,
          createdAt: DateTime.now(),
          tags: tags ?? [],
        );
      }
      
      await db.put(_notesBox, knowledgeId, note.toJson());
      debugPrint('📝 Note saved for: $knowledgeId');
    } catch (e) {
      debugPrint('❌ saveNote error: $e');
    }
  }

  /// Get note for entry
  Future<KnowledgeNote?> getNote(String knowledgeId) async {
    await init();

    try {
      final data = SqliteStorageService.instance.getSync(_notesBox, knowledgeId);

      if (data != null) {
        return KnowledgeNote.fromJson(Map<String, dynamic>.from(data as Map));
      }

      return null;
    } catch (e) {
      debugPrint('❌ getNote error: $e');
      return null;
    }
  }

  /// Delete note
  Future<void> deleteNote(String knowledgeId) async {
    await init();

    try {
      await SqliteStorageService.instance.delete(_notesBox, knowledgeId);
      debugPrint('🗑️ Note deleted for: $knowledgeId');
    } catch (e) {
      debugPrint('❌ deleteNote error: $e');
    }
  }

  /// Get all entries with notes
  Future<List<KnowledgeEntry>> getEntriesWithNotes({String? world}) async {
    await init();

    try {
      final knowledgeIds = await SqliteStorageService.instance.getKeys(_notesBox);

      final List<KnowledgeEntry> entries = [];
      for (var id in knowledgeIds) {
        final entry = await getEntry(id);
        if (entry != null && (world == null || entry.world == world)) {
          entries.add(entry);
        }
      }

      return entries;
    } catch (e) {
      debugPrint('❌ getEntriesWithNotes error: $e');
      return [];
    }
  }

  // ==========================================
  // READING PROGRESS SYSTEM
  // ==========================================

  /// Update reading progress
  Future<void> updateProgress(String knowledgeId, {bool? isRead, int? progressPercent}) async {
    await init();

    try {
      final db = SqliteStorageService.instance;
      final existingData = db.getSync(_progressBox, knowledgeId);

      ReadingProgress progress;
      if (existingData != null) {
        final existing = ReadingProgress.fromJson(Map<String, dynamic>.from(existingData as Map));
        progress = ReadingProgress(
          knowledgeId: knowledgeId,
          isRead: isRead ?? existing.isRead,
          readAt: (isRead == true && existing.readAt == null) ? DateTime.now() : existing.readAt,
          progressPercent: progressPercent ?? existing.progressPercent,
          lastAccessedAt: DateTime.now(),
        );
      } else {
        progress = ReadingProgress(
          knowledgeId: knowledgeId,
          isRead: isRead ?? false,
          readAt: (isRead == true) ? DateTime.now() : null,
          progressPercent: progressPercent ?? 0,
          lastAccessedAt: DateTime.now(),
        );
      }

      await db.put(_progressBox, knowledgeId, progress.toJson());
    } catch (e) {
      debugPrint('❌ updateProgress error: $e');
    }
  }

  /// Get reading progress
  Future<ReadingProgress?> getProgress(String knowledgeId) async {
    await init();

    try {
      final data = SqliteStorageService.instance.getSync(_progressBox, knowledgeId);

      if (data != null) {
        return ReadingProgress.fromJson(Map<String, dynamic>.from(data as Map));
      }

      return null;
    } catch (e) {
      debugPrint('❌ getProgress error: $e');
      return null;
    }
  }

  /// Get read entries
  Future<List<KnowledgeEntry>> getReadEntries({String? world}) async {
    await init();

    try {
      final db = SqliteStorageService.instance;
      final keys = await db.getKeys(_progressBox);
      final List<KnowledgeEntry> readEntries = [];

      for (var key in keys) {
        final progressData = db.getSync(_progressBox, key);
        if (progressData == null) continue;
        final progress = ReadingProgress.fromJson(Map<String, dynamic>.from(progressData as Map));

        if (progress.isRead) {
          final entry = await getEntry(key);
          if (entry != null && (world == null || entry.world == world)) {
            readEntries.add(entry);
          }
        }
      }

      return readEntries;
    } catch (e) {
      debugPrint('❌ getReadEntries error: $e');
      return [];
    }
  }

  /// Get statistics
  Future<Map<String, int>> getStatistics(String world) async {
    final allEntries = await getAllEntries(world: world);
    final readEntries = await getReadEntries(world: world);
    final favorites = await getFavorites(world: world);
    final entriesWithNotes = await getEntriesWithNotes(world: world);
    
    return {
      'total': allEntries.length,
      'read': readEntries.length,
      'favorites': favorites.length,
      'with_notes': entriesWithNotes.length,
      'unread': allEntries.length - readEntries.length,
    };
  }

  // ==========================================
  // RECOMMENDATIONS (Simple AI)
  // ==========================================

  /// Get recommended entries based on user's reading history
  Future<List<KnowledgeEntry>> getRecommendations(String world, {int limit = 5}) async {
    final readEntries = await getReadEntries(world: world);
    final favorites = await getFavorites(world: world);
    
    // Collect tags from read and favorited entries
    final Set<String> userInterestTags = {};
    for (var entry in [...readEntries, ...favorites]) {
      userInterestTags.addAll(entry.tags);
    }
    
    // Get all entries
    final allEntries = await getAllEntries(world: world);
    
    // Score entries based on matching tags
    final Map<KnowledgeEntry, int> scoredEntries = {};
    for (var entry in allEntries) {
      // Skip already read entries
      final isRead = readEntries.any((e) => e.id == entry.id);
      if (isRead) continue;
      
      // Calculate score
      int score = 0;
      for (var tag in entry.tags) {
        if (userInterestTags.contains(tag)) {
          score += 2; // High weight for matching tags
        }
      }
      
      // Bonus for popular entries
      score += (entry.viewCount / 10).floor();
      score += (entry.rating * 2).floor();
      
      if (score > 0) {
        scoredEntries[entry] = score;
      }
    }
    
    // Sort by score and return top N
    final sorted = scoredEntries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get popular entries (most viewed/rated)
  Future<List<KnowledgeEntry>> getPopular(String world, {int limit = 10}) async {
    final entries = await getAllEntries(world: world);
    
    // Sort by view count and rating
    entries.sort((a, b) {
      final scoreA = a.viewCount + (a.rating * 10).toInt();
      final scoreB = b.viewCount + (b.rating * 10).toInt();
      return scoreB.compareTo(scoreA);
    });
    
    return entries.take(limit).toList();
  }

  /// Get recently added entries
  Future<List<KnowledgeEntry>> getRecent(String world, {int limit = 10}) async {
    final entries = await getAllEntries(world: world);
    
    // Sort by creation date
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return entries.take(limit).toList();
  }

  // ==========================================
  // STREAM (for real-time updates)
  // ==========================================

  Stream<List<KnowledgeEntry>> watchEntries(String world) {
    // Initial load
    getAllEntries(world: world).then((entries) {
      _knowledgeStreamController.add(entries);
    });
    
    // Return stream
    return _knowledgeStreamController.stream;
  }

  void dispose() {
    _knowledgeStreamController.close();
  }
}
