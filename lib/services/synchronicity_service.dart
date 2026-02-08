import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/spirit_extended_models.dart';
import '../services/storage_service.dart';

/// ============================================
/// SYNCHRONICITY SERVICE
/// Verwaltet Synchronizitäts-Einträge
/// ============================================

class SynchronicityService extends ChangeNotifier {
  // Singleton Pattern
  static final SynchronicityService _instance = SynchronicityService._internal();
  factory SynchronicityService() => _instance;
  SynchronicityService._internal();

  // Alle Einträge
  List<SynchronicityEntry> _entries = [];

  // Stream für Live-Updates
  final _entriesController = StreamController<List<SynchronicityEntry>>.broadcast();
  Stream<List<SynchronicityEntry>> get entriesStream => _entriesController.stream;

  // Hive Box Name
  static const String _boxName = 'synchronicity_entries';

  /// Initialisierung
  Future<void> init() async {
    await _loadEntries();
    if (kDebugMode) {
      debugPrint('🌟 SynchronicityService initialisiert: ${_entries.length} Einträge');
    }
  }

  /// Lade alle Einträge
  Future<void> _loadEntries() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('entries');
      
      if (data != null && data is List) {
        _entries = data
            .map((json) => SynchronicityEntry.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList();
        
        // Sortiere nach Datum (neueste zuerst)
        _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      _entriesController.add(_entries);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Laden der Synchronizitäten: $e');
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
    required String event,
    required String meaning,
    List<String>? tags,
    List<int>? numbers,
    int significance = 3,
  }) async {
    try {
      final entry = SynchronicityEntry(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        event: event,
        meaning: meaning,
        tags: tags ?? [],
        numbers: numbers ?? [],
        significance: significance,
      );
      
      _entries.insert(0, entry); // Am Anfang einfügen (neueste zuerst)
      
      await _saveEntries();
      
      // Punkte hinzufügen (+5 pro Synchronizität)
      await StorageService().addPoints(5, 'synchronicity_logged');
      
      // Achievement-Check
      // await AchievementService().checkAchievements();
      
      _entriesController.add(_entries);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✨ Synchronizität erstellt: $event (+5 Punkte)');
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
    String? event,
    String? meaning,
    List<String>? tags,
    List<int>? numbers,
    int? significance,
  }) async {
    try {
      final index = _entries.indexWhere((e) => e.id == id);
      if (index == -1) return;
      
      final old = _entries[index];
      
      final updated = SynchronicityEntry(
        id: old.id,
        timestamp: old.timestamp,
        event: event ?? old.event,
        meaning: meaning ?? old.meaning,
        tags: tags ?? old.tags,
        numbers: numbers ?? old.numbers,
        significance: significance ?? old.significance,
      );
      
      _entries[index] = updated;
      
      await _saveEntries();
      
      _entriesController.add(_entries);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Synchronizität aktualisiert: $id');
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
        debugPrint('🗑️ Synchronizität gelöscht: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Löschen: $e');
      }
    }
  }

  /// Alle Einträge
  List<SynchronicityEntry> get entries => _entries;

  /// Anzahl Einträge
  int get count => _entries.length;

  /// Einträge nach Bedeutung (Significance)
  List<SynchronicityEntry> getEntriesBySignificance(int minSignificance) {
    return _entries.where((e) => e.significance >= minSignificance).toList();
  }

  /// Einträge nach Tag
  List<SynchronicityEntry> getEntriesByTag(String tag) {
    return _entries.where((e) => e.tags.contains(tag)).toList();
  }

  /// Einträge mit bestimmter Zahl
  List<SynchronicityEntry> getEntriesWithNumber(int number) {
    return _entries.where((e) => e.numbers.contains(number)).toList();
  }

  /// Häufigste Zahlen
  Map<int, int> get mostFrequentNumbers {
    final numberCounts = <int, int>{};
    
    for (final entry in _entries) {
      for (final number in entry.numbers) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }
    
    // Sortiere nach Häufigkeit
    final sorted = numberCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sorted.take(10)); // Top 10
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

  /// Durchschnittliche Bedeutung
  double get averageSignificance {
    if (_entries.isEmpty) return 0.0;
    final sum = _entries.fold<int>(0, (sum, e) => sum + e.significance);
    return sum / _entries.length;
  }

  /// Einträge der letzten X Tage
  List<SynchronicityEntry> getRecentEntries(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Einträge nach Monat gruppiert
  Map<String, List<SynchronicityEntry>> get entriesByMonth {
    final grouped = <String, List<SynchronicityEntry>>{};
    
    for (final entry in _entries) {
      final monthKey = '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(entry);
    }
    
    return grouped;
  }

  /// Vorgeschlagene Tags (basierend auf Häufigkeit)
  List<String> get suggestedTags {
    final commonTags = [
      '11:11',
      '22:22',
      'Wiederkehrende Zahlen',
      'Traum',
      'Begegnung',
      'Zeichen',
      'Botschaft',
      'Zufall',
      'Vorahnung',
      'Déjà-vu',
    ];
    
    // Kombiniere mit benutzerdefinierten häufigen Tags
    final userTags = mostFrequentTags.keys.take(5).toList();
    
    return [...commonTags, ...userTags]..toSet().toList();
  }

  /// Dispose
  @override
  void dispose() {
    _entriesController.close();
    super.dispose();
  }
}
