import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/spirit_extended_models.dart';
import '../models/energie_profile.dart';
import '../models/spirit_practices_database.dart';
import 'storage_service.dart';

/// ============================================
/// DAILY SPIRIT PRACTICE SERVICE
/// Generiert tägliche Spirit-Übungen basierend auf Profil
/// ============================================

class DailySpiritPracticeService extends ChangeNotifier {
  // Singleton Pattern
  static final DailySpiritPracticeService _instance = 
      DailySpiritPracticeService._internal();
  factory DailySpiritPracticeService() => _instance;
  DailySpiritPracticeService._internal();

  // Aktuelle Übungen
  List<DailySpiritPractice> _todaysPractices = [];

  // Stream für Live-Updates
  final _practicesController = StreamController<List<DailySpiritPractice>>.broadcast();
  Stream<List<DailySpiritPractice>> get practicesStream => _practicesController.stream;

  // Random-Generator mit Seed für Konsistenz
  final Random _random = Random();

  /// Initialisierung
  Future<void> init() async {
    await loadTodaysPractices();
    if (kDebugMode) {
      debugPrint('🧘 DailySpiritPracticeService initialisiert');
    }
  }

  /// Lade heutige Übungen
  Future<void> loadTodaysPractices() async {
    try {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      // Prüfen ob bereits generiert
      final storedPractices = await _loadStoredPractices(todayKey);
      
      if (storedPractices.isNotEmpty) {
        _todaysPractices = storedPractices;
      } else {
        // Neu generieren
        await generateTodaysPractices();
      }
      
      _practicesController.add(_todaysPractices);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ ${_todaysPractices.length} Übungen geladen');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Laden der Übungen: $e');
      }
    }
  }

  /// Generiere neue Übungen für heute
  Future<void> generateTodaysPractices() async {
    try {
      final profile = StorageService().getEnergieProfile();
      final today = DateTime.now();
      
      // 3-4 Übungen pro Tag
      final practiceCount = 3 + _random.nextInt(2); // 3 oder 4
      
      _todaysPractices.clear();
      
      for (int i = 0; i < practiceCount; i++) {
        final practice = _generatePractice(profile, today, i);
        _todaysPractices.add(practice);
      }
      
      // Speichern
      await _saveTodaysPractices();
      
      _practicesController.add(_todaysPractices);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✨ ${_todaysPractices.length} neue Übungen generiert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Generieren: $e');
      }
    }
  }

  /// Generiere einzelne Übung
  DailySpiritPractice _generatePractice(
    EnergieProfile? profile,
    DateTime date,
    int index,
  ) {
    // Kategorie basierend auf Wochentag und Index
    final category = _selectCategory(date, index);
    
    // Chakra des Tages
    final chakra = _getChakraForDay(date.weekday);
    
    // Numerologie-Basierung (falls Profil vorhanden)
    final basedOn = profile != null ? _getBasedOn(profile, category) : 'cycle';
    
    // Übungs-Template aus Datenbank
    final template = _getPracticeTemplate(category, chakra, basedOn);
    
    return DailySpiritPractice(
      id: 'practice_${date.millisecondsSinceEpoch}_$index',
      title: template['title'] as String,
      description: template['description'] as String,
      category: category,
      durationMinutes: template['duration'] as int,
      basedOn: basedOn,
      recommendedDate: date,
      completed: false,
    );
  }

  /// Kategorie-Auswahl (intelligent)
  String _selectCategory(DateTime date, int index) {
    // Wochentags-Mapping für primäre Kategorie
    final primaryCategory = _getCategoryForDay(date.weekday);
    
    // Bei Index 0: Primäre Kategorie
    if (index == 0) return primaryCategory;
    
    // Sonst: Rotation durch andere Kategorien
    final categories = ['meditation', 'breathing', 'chakra', 'journal'];
    categories.remove(primaryCategory);
    
    return categories[index % categories.length];
  }

  /// Wochentags-Kategorie-Mapping
  String _getCategoryForDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'meditation'; // Start der Woche: Meditation
      case DateTime.tuesday:
        return 'breathing'; // Energie aufbauen
      case DateTime.wednesday:
        return 'chakra'; // Mitte der Woche: Balance
      case DateTime.thursday:
        return 'journal'; // Reflexion
      case DateTime.friday:
        return 'meditation'; // Woche abschließen
      case DateTime.saturday:
        return 'breathing'; // Wochenende: Entspannung
      case DateTime.sunday:
        return 'chakra'; // Sonntag: Spiritualität
      default:
        return 'meditation';
    }
  }

  /// Chakra des Tages
  String _getChakraForDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Wurzel'; // Erdung für Wochenstart
      case DateTime.tuesday:
        return 'Sakral'; // Kreativität
      case DateTime.wednesday:
        return 'Solarplexus'; // Kraft in der Mitte
      case DateTime.thursday:
        return 'Herz'; // Mitgefühl
      case DateTime.friday:
        return 'Hals'; // Kommunikation
      case DateTime.saturday:
        return 'Stirn'; // Intuition
      case DateTime.sunday:
        return 'Krone'; // Spiritualität
      default:
        return 'Herz';
    }
  }

  /// Basierung ermitteln
  String _getBasedOn(EnergieProfile profile, String category) {
    if (category == 'chakra') return 'chakra';
    if (category == 'journal') return 'cycle';
    
    // Numerologie für Meditation/Breathing
    return 'archetype';
  }

  /// Übungs-Template aus Datenbank
  Map<String, dynamic> _getPracticeTemplate(
    String category,
    String chakra,
    String basedOn,
  ) {
    // Nutze Spirit-Practices-Database
    return SpiritPracticesDatabase.getTemplate(category, chakra);
  }

  /// Übung abschließen
  Future<void> completePractice(String practiceId) async {
    try {
      final index = _todaysPractices.indexWhere((p) => p.id == practiceId);
      if (index == -1) return;
      
      final practice = _todaysPractices[index];
      final completed = practice.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      
      _todaysPractices[index] = completed;
      
      // Speichern
      await _saveTodaysPractices();
      
      // Punkte hinzufügen (+10 pro Übung)
      await StorageService().addPoints(10, 'practice_${practice.category}');
      
      // Achievement-Check
      // await AchievementService().checkAchievements();
      
      _practicesController.add(_todaysPractices);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Übung abgeschlossen: ${practice.title} (+10 Punkte)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Abschließen: $e');
      }
    }
  }

  /// Anzahl abgeschlossener Übungen heute
  int get completedCount => _todaysPractices.where((p) => p.completed).length;

  /// Anzahl gesamt Übungen heute
  int get totalCount => _todaysPractices.length;

  /// Fortschritt in Prozent
  double get progressPercent {
    if (totalCount == 0) return 0.0;
    return (completedCount / totalCount) * 100;
  }

  /// Heutige Übungen
  List<DailySpiritPractice> get todaysPractices => _todaysPractices;

  /// Gespeicherte Übungen laden
  Future<List<DailySpiritPractice>> _loadStoredPractices(String dateKey) async {
    try {
      final box = await Hive.openBox('daily_practices');
      final data = box.get(dateKey);
      
      if (data != null && data is List) {
        return data
            .map((json) => DailySpiritPractice.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Laden: $e');
      }
      return [];
    }
  }

  /// Heutige Übungen speichern
  Future<void> _saveTodaysPractices() async {
    try {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      final box = await Hive.openBox('daily_practices');
      final data = _todaysPractices.map((p) => p.toJson()).toList();
      
      await box.put(todayKey, data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fehler beim Speichern: $e');
      }
    }
  }

  /// Dispose
  @override
  void dispose() {
    _practicesController.close();
    super.dispose();
  }
}
