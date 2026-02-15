import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Offline Storage Service - Artikel für Offline-Zugriff speichern
class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _articlesBoxName = 'offline_articles';
  static const String _metadataBoxName = 'offline_metadata';
  
  Box<dynamic>? _articlesBox;
  Box<dynamic>? _metadataBox;

  /// Initialisierung
  Future<void> initialize() async {
    await Hive.initFlutter();
    _articlesBox = await Hive.openBox(_articlesBoxName);
    _metadataBox = await Hive.openBox(_metadataBoxName);
    debugPrint('✅ Offline Storage Service initialisiert');
  }

  /// Artikel offline speichern
  Future<bool> saveArticle({
    required String articleId,
    required String title,
    required String content,
    required String category,
    required String world, // 'materie' oder 'energie'
    String? imageUrl,
    String? author,
    DateTime? publishedDate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final article = {
        'id': articleId,
        'title': title,
        'content': content,
        'category': category,
        'world': world,
        'imageUrl': imageUrl,
        'author': author,
        'publishedDate': publishedDate?.toIso8601String(),
        'savedAt': DateTime.now().toIso8601String(),
        'metadata': metadata,
      };

      await _articlesBox?.put(articleId, jsonEncode(article));
      
      // Metadaten aktualisieren
      await _updateMetadata(articleId, world, category);
      
      debugPrint('✅ Artikel gespeichert: $title');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern: $e');
      return false;
    }
  }

  /// Artikel laden
  Future<Map<String, dynamic>?> getArticle(String articleId) async {
    try {
      final data = _articlesBox?.get(articleId);
      if (data == null) return null;
      
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Fehler beim Laden: $e');
      return null;
    }
  }

  /// Alle gespeicherten Artikel abrufen
  Future<List<Map<String, dynamic>>> getAllArticles({
    String? world,
    String? category,
  }) async {
    try {
      final articles = <Map<String, dynamic>>[];
      
      for (var key in _articlesBox?.keys ?? []) {
        final data = _articlesBox?.get(key);
        if (data != null) {
          final article = jsonDecode(data) as Map<String, dynamic>;
          
          // Filter anwenden
          if (world != null && article['world'] != world) continue;
          if (category != null && article['category'] != category) continue;
          
          articles.add(article);
        }
      }
      
      // Sortieren nach Speicherdatum (neueste zuerst)
      articles.sort((a, b) {
        final dateA = DateTime.parse(a['savedAt'] as String);
        final dateB = DateTime.parse(b['savedAt'] as String);
        return dateB.compareTo(dateA);
      });
      
      return articles;
    } catch (e) {
      debugPrint('❌ Fehler beim Abrufen aller Artikel: $e');
      return [];
    }
  }

  /// Artikel löschen
  Future<bool> deleteArticle(String articleId) async {
    try {
      await _articlesBox?.delete(articleId);
      await _removeFromMetadata(articleId);
      debugPrint('✅ Artikel gelöscht: $articleId');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Löschen: $e');
      return false;
    }
  }

  /// Alle Artikel löschen
  Future<bool> clearAllArticles() async {
    try {
      await _articlesBox?.clear();
      await _metadataBox?.clear();
      debugPrint('✅ Alle Artikel gelöscht');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Löschen aller Artikel: $e');
      return false;
    }
  }

  /// Prüfen ob Artikel bereits gespeichert ist
  bool isArticleSaved(String articleId) {
    return _articlesBox?.containsKey(articleId) ?? false;
  }

  /// Anzahl gespeicherter Artikel
  int getArticleCount({String? world}) {
    if (world == null) {
      return _articlesBox?.length ?? 0;
    }
    
    int count = 0;
    for (var key in _articlesBox?.keys ?? []) {
      final data = _articlesBox?.get(key);
      if (data != null) {
        final article = jsonDecode(data) as Map<String, dynamic>;
        if (article['world'] == world) count++;
      }
    }
    return count;
  }

  /// Speicherplatz-Info
  Future<Map<String, dynamic>> getStorageInfo() async {
    final totalArticles = _articlesBox?.length ?? 0;
    final materieCount = getArticleCount(world: 'materie');
    final energieCount = getArticleCount(world: 'energie');
    
    // Geschätzter Speicherplatz (ca. 50KB pro Artikel)
    final estimatedSizeMB = (totalArticles * 50) / 1024;
    
    return {
      'totalArticles': totalArticles,
      'materieArticles': materieCount,
      'energieArticles': energieCount,
      'estimatedSizeMB': estimatedSizeMB.toStringAsFixed(2),
    };
  }

  /// Metadaten aktualisieren
  Future<void> _updateMetadata(String articleId, String world, String category) async {
    try {
      final metadata = _metadataBox?.get('stats', defaultValue: <String, dynamic>{}) as Map;
      
      // Artikel-IDs nach Welt
      final worldArticles = List<String>.from(metadata['${world}_articles'] ?? []);
      if (!worldArticles.contains(articleId)) {
        worldArticles.add(articleId);
        metadata['${world}_articles'] = worldArticles;
      }
      
      // Kategorien-Counter
      final categoryKey = '${world}_$category';
      metadata[categoryKey] = (metadata[categoryKey] ?? 0) + 1;
      
      // Letztes Update
      metadata['lastUpdate'] = DateTime.now().toIso8601String();
      
      await _metadataBox?.put('stats', metadata);
    } catch (e) {
      debugPrint('⚠️ Fehler beim Aktualisieren der Metadaten: $e');
    }
  }

  /// Aus Metadaten entfernen
  Future<void> _removeFromMetadata(String articleId) async {
    try {
      final metadata = _metadataBox?.get('stats', defaultValue: <String, dynamic>{}) as Map;
      
      // Aus beiden Welten entfernen
      for (var world in ['materie', 'energie']) {
        final worldArticles = List<String>.from(metadata['${world}_articles'] ?? []);
        worldArticles.remove(articleId);
        metadata['${world}_articles'] = worldArticles;
      }
      
      await _metadataBox?.put('stats', metadata);
    } catch (e) {
      debugPrint('⚠️ Fehler beim Entfernen aus Metadaten: $e');
    }
  }

  /// Alte Artikel automatisch löschen (älter als X Tage)
  Future<int> cleanOldArticles({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      int deletedCount = 0;
      
      final keysToDelete = <String>[];
      
      for (var key in _articlesBox?.keys ?? []) {
        final data = _articlesBox?.get(key);
        if (data != null) {
          final article = jsonDecode(data) as Map<String, dynamic>;
          final savedAt = DateTime.parse(article['savedAt'] as String);
          
          if (savedAt.isBefore(cutoffDate)) {
            keysToDelete.add(key as String);
          }
        }
      }
      
      for (var key in keysToDelete) {
        await deleteArticle(key);
        deletedCount++;
      }
      
      debugPrint('✅ $deletedCount alte Artikel gelöscht');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Fehler beim Bereinigen alter Artikel: $e');
      return 0;
    }
  }

  /// Export aller Artikel (für Backup)
  Future<String> exportArticles() async {
    try {
      final articles = await getAllArticles();
      return jsonEncode(articles);
    } catch (e) {
      debugPrint('❌ Fehler beim Exportieren: $e');
      return '[]';
    }
  }

  /// Import von Artikeln (aus Backup)
  Future<int> importArticles(String jsonData) async {
    try {
      final articles = jsonDecode(jsonData) as List;
      int importedCount = 0;
      
      for (var article in articles) {
        final articleMap = article as Map<String, dynamic>;
        await saveArticle(
          articleId: articleMap['id'],
          title: articleMap['title'],
          content: articleMap['content'],
          category: articleMap['category'],
          world: articleMap['world'],
          imageUrl: articleMap['imageUrl'],
          author: articleMap['author'],
          publishedDate: articleMap['publishedDate'] != null 
              ? DateTime.parse(articleMap['publishedDate'])
              : null,
          metadata: articleMap['metadata'],
        );
        importedCount++;
      }
      
      debugPrint('✅ $importedCount Artikel importiert');
      return importedCount;
    } catch (e) {
      debugPrint('❌ Fehler beim Importieren: $e');
      return 0;
    }
  }
}
