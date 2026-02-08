import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/spirit_extended_models.dart';
import '../services/storage_service.dart';

/// ============================================
/// SPIRIT JOURNAL SERVICE
/// Verwaltet Journal-Einträge
/// ============================================

class SpiritJournalService extends ChangeNotifier {
  // Singleton Pattern
  static final SpiritJournalService _instance = SpiritJournalService._internal();
  factory SpiritJournalService() => _instance;
  SpiritJournalService._internal();

  // Alle Einträge
  List<SpiritJournalEntry> _entries = [];

  // Stream für Live-Updates
  final _entriesController = StreamController<List<SpiritJournalEntry>>.broadcast();
  Stream<List<SpiritJournalEntry>> get entriesStream => _entriesController.stream;

  // Hive Box Name
  static const String _boxName = 'spirit_journal_entries';

  /// Kategorien
  static const List<String> categories = [
    'dream',
    'meditation',
    'synchronicity',
    'insight',
    'gratitude',
  ];

  /// Moods
  static const List<String> moods = [
    'joy',
    'peace',
    'sadness',
    'fear',
    'anger',
    'love',
    'neutral',
  ];

  /// Initialisierung
  Future<void> init() async {
    await _loadEntries();
    if (kDebugMode) {
      debugPrint('📖 SpiritJournalService initialisiert: ${_entries.length} Einträge');
    }
  }

  /// Lade alle Einträge
  Future<void> _loadEntries() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('entries');
      
      if (data != null && data is List) {
        _entries = data
            .map((json) => SpiritJournalEntry.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList();
        
        // Sortiere nach Datum (neueste zuerst)
        _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      _entriesController.add(_entries);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Laden der Journal-Einträge: $e');
      }
    }
  }

  /// Speichere Einträge
  Future<void> _saveEntries() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = _entries.map((e) => e.toJson()).toList();
      await box.put('entries', data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Speichern: $e');
      }
    }
  }

  /// Erstelle neuen Eintrag
  Future<void> createEntry({
    required String category,
    required String content,
    required String mood,
    List<String>? tags,
    int? rating,
  }) async {
    try {
      final entry = SpiritJournalEntry(
        id: 'journal_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        category: category,
        content: content,
        mood: mood,
        tags: tags ?? [],
        rating: rating,
      );
      
      _entries.insert(0, entry); // Am Anfang einfügen (neueste zuerst)
      
      await _saveEntries();
      
      // Punkte hinzufügen (+8 pro Journal-Eintrag)
      await StorageService().addPoints(8, 'journal_entry');
      
      // Achievement-Check
      // await AchievementService().checkAchievements();
      
      _entriesController.add(_entries);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('📝 Journal-Eintrag erstellt: $category (+8 Punkte)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Erstellen: $e');
      }
    }
  }

  /// Update Eintrag
  Future<void> updateEntry(
    String id, {
    String? category,
    String? content,
    String? mood,
    List<String>? tags,
    int? rating,
  }) async {
    try {
      final index = _entries.indexWhere((e) => e.id == id);
      if (index == -1) return;
      
      final old = _entries[index];
      
      final updated = SpiritJournalEntry(
        id: old.id,
        timestamp: old.timestamp,
        category: category ?? old.category,
        content: content ?? old.content,
        mood: mood ?? old.mood,
        tags: tags ?? old.tags,
        rating: rating ?? old.rating,
      );
      
      _entries[index] = updated;
      
      await _saveEntries();
      
      _entriesController.add(_entries);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Journal-Eintrag aktualisiert: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Aktualisieren: $e');
      }
    }
  }

  /// Lösche Eintrag
  Future<void> deleteEntry(String id) async {
    try {
      _entries.removeWhere((e) => e.id == id);
      
      await _saveEntries();
      
      _entriesController.add(_entries);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('🗑️ Journal-Eintrag gelöscht: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Löschen: $e');
      }
    }
  }

  /// Alle Einträge
  List<SpiritJournalEntry> get entries => _entries;

  /// Anzahl Einträge
  int get count => _entries.length;

  /// Einträge nach Kategorie
  List<SpiritJournalEntry> getEntriesByCategory(String category) {
    return _entries.where((e) => e.category == category).toList();
  }

  /// Einträge nach Mood
  List<SpiritJournalEntry> getEntriesByMood(String mood) {
    return _entries.where((e) => e.mood == mood).toList();
  }

  /// Einträge nach Tag
  List<SpiritJournalEntry> getEntriesByTag(String tag) {
    return _entries.where((e) => e.tags.contains(tag)).toList();
  }

  /// Einträge der letzten X Tage
  List<SpiritJournalEntry> getRecentEntries(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Mood-Verteilung (Statistik)
  Map<String, int> get moodDistribution {
    final distribution = <String, int>{};
    
    for (final mood in moods) {
      distribution[mood] = 0;
    }
    
    for (final entry in _entries) {
      distribution[entry.mood] = (distribution[entry.mood] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Häufigste Tags
  Map<String, int> get mostFrequentTags {
    final tagCounts = <String, int>{};
    
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    // Sortiere nach Häufigkeit
    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sorted);
  }

  /// Durchschnittliches Rating
  double get averageRating {
    final rated = _entries.where((e) => e.rating != null).toList();
    if (rated.isEmpty) return 0.0;
    
    final sum = rated.fold<int>(0, (sum, e) => sum + e.rating!);
    return sum / rated.length;
  }

  /// Kategorie-Verteilung
  Map<String, int> get categoryDistribution {
    final distribution = <String, int>{};
    
    for (final category in categories) {
      distribution[category] = 0;
    }
    
    for (final entry in _entries) {
      distribution[entry.category] = (distribution[entry.category] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Einträge nach Monat gruppiert
  Map<String, List<SpiritJournalEntry>> get entriesByMonth {
    final grouped = <String, List<SpiritJournalEntry>>{};
    
    for (final entry in _entries) {
      final monthKey = '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(entry);
    }
    
    return grouped;
  }

  /// Aktueller Mood-Streak (Tage hintereinander gejournal)
  int get journalStreak {
    if (_entries.isEmpty) return 0;
    
    int streak = 0;
    final today = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final hasEntry = _entries.any((e) => 
        e.timestamp.year == checkDate.year &&
        e.timestamp.month == checkDate.month &&
        e.timestamp.day == checkDate.day
      );
      
      if (hasEntry) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Vorgeschlagene Tags (basierend auf Häufigkeit)
  List<String> get suggestedTags {
    final commonTags = [
      'Dankbarkeit',
      'Reflexion',
      'Transformation',
      'Heilung',
      'Klarheit',
      'Vision',
      'Herausforderung',
      'Segen',
      'Erkenntnis',
      'Wachstum',
    ];
    
    // Kombiniere mit benutzerdefinierten häufigen Tags
    final userTags = mostFrequentTags.keys.take(5).toList();
    
    return [...commonTags, ...userTags]..toSet().toList();
  }

  /// Kategorie-Name (deutsch)
  static String getCategoryName(String category) {
    switch (category) {
      case 'dream':
        return 'Traum';
      case 'meditation':
        return 'Meditation';
      case 'synchronicity':
        return 'Synchronizität';
      case 'insight':
        return 'Erkenntnis';
      case 'gratitude':
        return 'Dankbarkeit';
      default:
        return category;
    }
  }

  /// Mood-Name (deutsch)
  static String getMoodName(String mood) {
    switch (mood) {
      case 'joy':
        return 'Freude';
      case 'peace':
        return 'Frieden';
      case 'sadness':
        return 'Traurigkeit';
      case 'fear':
        return 'Angst';
      case 'anger':
        return 'Wut';
      case 'love':
        return 'Liebe';
      case 'neutral':
        return 'Neutral';
      default:
        return mood;
    }
  }

  /// Mood-Emoji
  static String getMoodEmoji(String mood) {
    switch (mood) {
      case 'joy':
        return '😊';
      case 'peace':
        return '☮️';
      case 'sadness':
        return '😢';
      case 'fear':
        return '😰';
      case 'anger':
        return '😠';
      case 'love':
        return '❤️';
      case 'neutral':
        return '😐';
      default:
        return '📝';
    }
  }

  /// Kategorie-Emoji
  static String getCategoryEmoji(String category) {
    switch (category) {
      case 'dream':
        return '🌙';
      case 'meditation':
        return '🧘';
      case 'synchronicity':
        return '✨';
      case 'insight':
        return '💡';
      case 'gratitude':
        return '🙏';
      default:
        return '📝';
    }
  }

  /// Dispose
  @override
  void dispose() {
    _entriesController.close();
    super.dispose();
  }
}
