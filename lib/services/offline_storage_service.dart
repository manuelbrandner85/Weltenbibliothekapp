import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../core/db/app_database.dart';

/// Offline Storage Service – Artikel für Offline-Zugriff (SQLite)
class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  Future<void> initialize() async {
    await AppDatabase.instance.db; // ensure DB is open
    debugPrint('✅ Offline Storage Service initialisiert');
  }

  /// Artikel offline speichern
  Future<bool> saveArticle({
    required String articleId,
    required String title,
    required String content,
    required String category,
    required String world,
    String? imageUrl,
    String? author,
    DateTime? publishedDate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final db = await AppDatabase.instance.db;
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
      await db.insert(
        'offline_articles',
        {'id': articleId, 'content': jsonEncode(article), 'saved_at': article['savedAt']!},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
      final db = await AppDatabase.instance.db;
      final rows = await db.query('offline_articles', where: 'id = ?', whereArgs: [articleId]);
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['content'] as String) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Fehler beim Laden: $e');
      return null;
    }
  }

  /// Alle gespeicherten Artikel abrufen
  Future<List<Map<String, dynamic>>> getAllArticles({String? world, String? category}) async {
    try {
      final db = await AppDatabase.instance.db;
      final rows = await db.query('offline_articles', orderBy: 'saved_at DESC');
      final articles = rows
          .map((r) => jsonDecode(r['content'] as String) as Map<String, dynamic>)
          .where((a) {
            if (world != null && a['world'] != world) return false;
            if (category != null && a['category'] != category) return false;
            return true;
          })
          .toList();
      return articles;
    } catch (e) {
      debugPrint('❌ Fehler beim Abrufen aller Artikel: $e');
      return [];
    }
  }

  /// Artikel löschen
  Future<bool> deleteArticle(String articleId) async {
    try {
      final db = await AppDatabase.instance.db;
      await db.delete('offline_articles', where: 'id = ?', whereArgs: [articleId]);
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
      final db = await AppDatabase.instance.db;
      await db.delete('offline_articles');
      debugPrint('✅ Alle Artikel gelöscht');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Löschen aller Artikel: $e');
      return false;
    }
  }

  /// Prüfen ob Artikel bereits gespeichert ist
  Future<bool> isArticleSaved(String articleId) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('offline_articles',
        columns: ['id'], where: 'id = ?', whereArgs: [articleId]);
    return rows.isNotEmpty;
  }

  /// Anzahl gespeicherter Artikel
  Future<int> getArticleCount({String? world}) async {
    try {
      final db = await AppDatabase.instance.db;
      if (world == null) {
        final result = await db.rawQuery('SELECT COUNT(*) as c FROM offline_articles');
        return (result.first['c'] as int?) ?? 0;
      }
      final rows = await db.query('offline_articles');
      return rows
          .map((r) => jsonDecode(r['content'] as String) as Map<String, dynamic>)
          .where((a) => a['world'] == world)
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// Speicherplatz-Info
  Future<Map<String, dynamic>> getStorageInfo() async {
    final total   = await getArticleCount();
    final materie = await getArticleCount(world: 'materie');
    final energie = await getArticleCount(world: 'energie');
    return {
      'totalArticles':    total,
      'materieArticles':  materie,
      'energieArticles':  energie,
      'estimatedSizeMB':  ((total * 50) / 1024).toStringAsFixed(2),
    };
  }

  /// Alte Artikel automatisch löschen (älter als X Tage)
  Future<int> cleanOldArticles({int daysToKeep = 30}) async {
    try {
      final db = await AppDatabase.instance.db;
      final cutoff = DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();
      final count = await db.delete('offline_articles', where: 'saved_at < ?', whereArgs: [cutoff]);
      debugPrint('✅ $count alte Artikel gelöscht');
      return count;
    } catch (e) {
      debugPrint('❌ Fehler beim Bereinigen: $e');
      return 0;
    }
  }

  /// Export aller Artikel
  Future<String> exportArticles() async {
    try {
      return jsonEncode(await getAllArticles());
    } catch (_) {
      return '[]';
    }
  }

  /// Import von Artikeln
  Future<int> importArticles(String jsonData) async {
    try {
      final articles = jsonDecode(jsonData) as List;
      int count = 0;
      for (final a in articles) {
        final m = a as Map<String, dynamic>;
        final ok = await saveArticle(
          articleId:     m['id'] as String,
          title:         m['title'] as String,
          content:       m['content'] as String,
          category:      m['category'] as String,
          world:         m['world'] as String,
          imageUrl:      m['imageUrl'] as String?,
          author:        m['author'] as String?,
          publishedDate: m['publishedDate'] != null
              ? DateTime.tryParse(m['publishedDate'] as String)
              : null,
          metadata: m['metadata'] as Map<String, dynamic>?,
        );
        if (ok) count++;
      }
      debugPrint('✅ $count Artikel importiert');
      return count;
    } catch (e) {
      debugPrint('❌ Fehler beim Importieren: $e');
      return 0;
    }
  }
}
