import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../models/spirit_profile.dart';
import '../models/research_topic.dart';
import '../models/spirit_entry.dart';
import '../models/community_post.dart';
import '../models/spirit_extended_models.dart';
import '../models/app_data.dart'; // 🆕 NEUE DATENMODELLE
import '../core/exceptions/exception_guard.dart'; // 🛡️ EXCEPTION GUARD

/// Lokaler Storage Service mit Hive
/// Für offline-first Funktionalität
class StorageService {
  // Box-Namen (PLURAL für Unified Storage)
  static const String _materieProfileBox = 'materie_profiles';
  static const String _energieProfileBox = 'energie_profiles';
  static const String _researchTopicsBox = 'research_topics';
  static const String _spiritEntriesBox = 'spirit_entries';
  static const String _communityPostsBox = 'community_posts';
  
  // NEUE BOXEN FÜR ERWEITERTE FEATURES
  static const String _dailyPracticesBox = 'daily_practices';
  static const String _synchronicityBox = 'synchronicity_entries';
  static const String _journalEntriesBox = 'journal_entries';
  static const String _partnerProfilesBox = 'partner_profiles';
  static const String _compatibilityBox = 'compatibility_analyses';
  static const String _weeklyHoroscopeBox = 'weekly_horoscope';
  static const String _spiritProgressBox = 'spirit_progress';
  
  // 🆕 TOP 10 VERBESSERUNGEN - NEUE BOXEN (v57)
  static const String _tarotReadingsBox = 'tarot_readings';
  static const String _moonJournalBox = 'moon_journal';
  static const String _crystalCollectionBox = 'crystal_collection';
  static const String _mantraChallengesBox = 'mantra_challenges';
  static const String _meditationSessionsBox = 'meditation_sessions';
  static const String _achievementsBox = 'achievements';
  static const String _toolStreaksBox = 'tool_streaks';
  
  // 🚀 TIER-1 MEGA UPGRADE BOXEN (v44.1.0)
  static const String _numerologyYearJourneyBox = 'numerology_year_journey';
  static const String _numerologyJournalBox = 'numerology_journal';
  static const String _numerologyMilestonesBox = 'numerology_milestones';
  static const String _chakraDailyScoresBox = 'chakra_daily_scores';
  static const String _chakraMeditationSessionsBox = 'chakra_meditation_sessions';
  static const String _chakraAffirmationsBox = 'chakra_affirmations';
  static const String _meditationSessionsEnhancedBox = 'meditation_sessions_enhanced';
  static const String _meditationPresetsBox = 'meditation_presets';
  static const String _tarotDailyCardsBox = 'tarot_daily_cards';
  static const String _tarotSpreadsBox = 'tarot_spreads';
  
  // 🆕 POST CREATION V2 BOXEN (v44.2.2)
  static const String _postDraftsBox = 'post_drafts'; // ignore: unused_field
  static const String _scheduledPostsBox = 'scheduled_posts'; // ignore: unused_field
  
  // Singleton Pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  /// 🔄 ONE-TIME MIGRATION: Alte Box-Namen → Neue Box-Namen
  Future<void> _migrateOldBoxes() async {
    await guardStorage(
      () async {
        // Materie: materie_profile → materie_profiles
        if (await Hive.boxExists('materie_profile')) {
          if (kDebugMode) debugPrint('🔄 Migration: materie_profile → materie_profiles');
          final oldBox = await Hive.openBox('materie_profile');
          final newBox = await Hive.openBox('materie_profiles');
          
          // Kopiere alle Daten
          for (var key in oldBox.keys) {
            await newBox.put(key, oldBox.get(key));
            if (kDebugMode) debugPrint('  ✅ Kopiert: $key');
          }
          
          // Lösche alte Box
          await oldBox.clear();
          await oldBox.close();
          await Hive.deleteBoxFromDisk('materie_profile');
          if (kDebugMode) debugPrint('  ✅ Alte Box gelöscht');
        }
        
        // Energie: energie_profile → energie_profiles
        if (await Hive.boxExists('energie_profile')) {
          if (kDebugMode) debugPrint('🔄 Migration: energie_profile → energie_profiles');
          final oldBox = await Hive.openBox('energie_profile');
          final newBox = await Hive.openBox('energie_profiles');
          
          // Kopiere alle Daten
          for (var key in oldBox.keys) {
            await newBox.put(key, oldBox.get(key));
            if (kDebugMode) debugPrint('  ✅ Kopiert: $key');
          }
          
          // Lösche alte Box
          await oldBox.clear();
          await oldBox.close();
          await Hive.deleteBoxFromDisk('energie_profile');
          if (kDebugMode) debugPrint('  ✅ Alte Box gelöscht');
        }
        
        if (kDebugMode) debugPrint('✅ Migration abgeschlossen');
      },
      operation: 'migrateOldBoxes',
      onError: (e, stack) async {
        if (kDebugMode) {
          debugPrint('💡 Keine alten Boxen vorhanden - OK');
        }
        // Return void (Function<Future<void>>)
      },
    );
  }
  
  /// Hive initialisieren (✅ ANDROID-OPTIMIERT: Nur kritische Boxen beim Start)
  Future<void> init() async {
    if (kDebugMode) {
      debugPrint('📦 Hive: Initialisierung starten...');
    }
    
    await Hive.initFlutter();
    
    if (kDebugMode) {
      debugPrint('📦 Hive: Flutter initialisiert');
    }
    
    // 🔄 MIGRATION: Alte Box-Namen zu neuen Box-Namen (ONE-TIME)
    await _migrateOldBoxes();
    
    // ✅ NUR KRITISCHE BOXEN beim Start öffnen (schneller App-Start!)
    // Alle anderen Boxen werden lazy geladen bei Bedarf
    await guardStorage(
      () async {
        await Hive.openBox(_materieProfileBox);
        if (kDebugMode) debugPrint('✅ Hive: materieProfile geöffnet');
        
        await Hive.openBox(_energieProfileBox);
        if (kDebugMode) debugPrint('✅ Hive: energieProfile geöffnet');
        
        await Hive.openBox(_researchTopicsBox);
        if (kDebugMode) debugPrint('✅ Hive: researchTopics geöffnet');
        
        await Hive.openBox(_communityPostsBox);
        if (kDebugMode) debugPrint('✅ Hive: communityPosts geöffnet');
        
        if (kDebugMode) {
          debugPrint('✅ Hive: Kritische Boxen geöffnet (4/25)');
          debugPrint('💡 Hive: Weitere Boxen werden bei Bedarf geladen');
        }
      },
      operation: 'openCriticalBoxes',
    );
    
    // ⚡ ALLE ANDEREN BOXEN werden lazy geladen via getBox()
    // Dies beschleunigt den App-Start erheblich!
  }
  
  // ============================================
  // GENERIC BOX ACCESS METHODS (für Dashboard)
  // ============================================
  
  /// Get Box (async) - für Dashboard Data Loading
  Future<Box> getBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }
  
  /// Get Box (sync) - für Dashboard Data Access
  Box getBoxSync(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open! Call getBox() first.');
    }
    return Hive.box(boxName);
  }

  // ═══════════════════════════════════════════════════════════════════
  // LAZY-OPEN SAFETY NET (Phase B)
  // ───────────────────────────────────────────────────────────────────
  // Ersetzt direkten Hive.box()-Zugriff durch zwei Helper:
  //   _ensureBox(name)  → async, garantiert geöffnete Box (opens lazy)
  //   _boxOrNull(name)  → sync, null wenn Box nicht offen
  //                       + triggert Async-Open im Hintergrund
  //
  // Damit verschwindet die ganze Klasse "HiveError: Box not found"
  // unabhängig von der Init-Reihenfolge in main.dart.
  // ═══════════════════════════════════════════════════════════════════

  /// Async: Öffnet die Box wenn nötig und gibt sie zurück.
  /// Idempotent, sicher bei parallelen Aufrufen.
  Future<Box> _ensureBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    return await Hive.openBox(name);
  }

  /// Sync: Gibt Box zurück wenn offen, sonst null.
  /// Öffnet die Box im Hintergrund fire-and-forget, damit der nächste
  /// Aufruf erfolgreich ist. Caller muss null-Fall gracefully behandeln
  /// (meist: leere Liste oder null zurückgeben).
  Box? _boxOrNull(String name) {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    unawaited(Hive.openBox(name).catchError((e) {
      if (kDebugMode) debugPrint('⚠️ Lazy openBox($name) fehlgeschlagen: $e');
      return Hive.box(name);
    }));
    return null;
  }
  
  // ============================================
  // MATERIE PROFILE
  // ============================================
  
  Future<void> saveMaterieProfile(MaterieProfile profile) async {
    final box = await _ensureBox(_materieProfileBox);
    await box.put('current_profile', profile.toJson());
  }

  MaterieProfile? getMaterieProfile() {
    final box = _boxOrNull(_materieProfileBox);
    if (box == null) return null;
    final data = box.get('current_profile') as Map?;
    if (data == null) return null;
    return MaterieProfile.fromJson(Map<String, dynamic>.from(data));
  }

  /// Materie-Profil löschen
  Future<void> deleteMaterieProfile() async {
    final box = await _ensureBox(_materieProfileBox);
    await box.delete('current_profile');
  }
  
  // ============================================
  // ENERGIE PROFILE
  // ============================================
  
  Future<void> saveEnergieProfile(EnergieProfile profile) async {
    final box = await _ensureBox(_energieProfileBox);
    await box.put('current_profile', profile.toJson());
  }

  EnergieProfile? getEnergieProfile() {
    final box = _boxOrNull(_energieProfileBox);
    if (box == null) return null;
    final data = box.get('current_profile') as Map?;
    if (data == null) return null;
    return EnergieProfile.fromJson(Map<String, dynamic>.from(data));
  }

  // 🔮 SPIRIT PROFILE METHODS
  SpiritProfile? getSpiritProfile() {
    final box = _boxOrNull(_energieProfileBox);
    if (box == null) return null;
    final data = box.get('current_profile') as Map?;
    if (data == null) return null;
    return SpiritProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveSpiritProfile(SpiritProfile profile) async {
    await guardStorage(
      () async {
        final box = await _ensureBox(_energieProfileBox);
        await box.put('current_profile', profile.toJson());
        if (kDebugMode) {
          debugPrint('✅ Spirit profile saved');
        }
      },
      operation: 'saveSpiritProfile',
      key: 'current_profile',
    );
  }

  Future<EnergieProfile?> loadEnergieProfile() async {
    return getEnergieProfile();
  }

  /// Energie-Profil löschen
  Future<void> deleteEnergieProfile() async {
    final box = await _ensureBox(_energieProfileBox);
    await box.delete('current_profile');
  }
  
  // ============================================
  // RESEARCH TOPICS (MATERIE)
  // ============================================
  
  Future<void> saveResearchTopic(ResearchTopic topic) async {
    final box = await _ensureBox(_researchTopicsBox);
    await box.put(topic.id, topic.toJson());
  }

  List<ResearchTopic> getResearchTopics() {
    final box = _boxOrNull(_researchTopicsBox);
    if (box == null) return [];
    return box.values
        .map((e) => ResearchTopic.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  
  // Async wrapper für Research Topics
  Future<List<ResearchTopic>> getAllResearchTopics() async {
    return getResearchTopics();
  }
  
  // ============================================
  // SPIRIT ENTRIES (ENERGIE)
  // ============================================
  
  Future<void> saveSpiritEntry(SpiritEntry entry) async {
    final box = await _ensureBox(_spiritEntriesBox);
    await box.put(entry.id, entry.toJson());
  }

  List<SpiritEntry> getSpiritEntries() {
    final box = _boxOrNull(_spiritEntriesBox);
    if (box == null) return [];
    return box.values
        .map((e) => SpiritEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  
  // Async wrapper für Spirit Entries
  Future<List<SpiritEntry>> getAllSpiritEntries() async {
    return getSpiritEntries();
  }
  
  // ============================================
  // COMMUNITY POSTS (beide Welten)
  // ============================================
  
  Future<void> saveCommunityPost(CommunityPost post) async {
    final box = await _ensureBox(_communityPostsBox);
    await box.put(post.id, post.toJson());
  }

  List<CommunityPost> getCommunityPosts(WorldType worldType) {
    final box = _boxOrNull(_communityPostsBox);
    if (box == null) return [];
    return box.values
        .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((post) => post.worldType == worldType)
        .toList();
  }

  // ============================================
  // UTILITY
  // ============================================

  Future<void> clearAll() async {
    await (await _ensureBox(_materieProfileBox)).clear();
    await (await _ensureBox(_energieProfileBox)).clear();
    await (await _ensureBox(_researchTopicsBox)).clear();
    await (await _ensureBox(_spiritEntriesBox)).clear();
    await (await _ensureBox(_communityPostsBox)).clear();
  }
  
  // ============================================
  // VORSCHLAG 1: TÄGLICHE SPIRIT-ÜBUNGEN
  // ============================================
  
  Future<void> saveDailyPractice(DailySpiritPractice practice) async {
    final box = await _ensureBox(_dailyPracticesBox);
    await box.put(practice.id, practice.toJson());
  }

  List<DailySpiritPractice> getDailyPractices({DateTime? forDate}) {
    final box = _boxOrNull(_dailyPracticesBox);
    if (box == null) return [];
    final practices = box.values
        .map((e) => DailySpiritPractice.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (forDate != null) {
      return practices.where((p) =>
        p.recommendedDate.year == forDate.year &&
        p.recommendedDate.month == forDate.month &&
        p.recommendedDate.day == forDate.day
      ).toList();
    }
    return practices;
  }
  
  // ============================================
  // VORSCHLAG 2: SYNCHRONIZITÄTS-TRACKER
  // ============================================
  
  Future<void> saveSynchronicity(SynchronicityEntry entry) async {
    final box = await _ensureBox(_synchronicityBox);
    await box.put(entry.id, entry.toJson());
  }

  List<SynchronicityEntry> getSynchronicities({int? lastDays}) {
    final box = _boxOrNull(_synchronicityBox);
    if (box == null) return [];
    final entries = box.values
        .map((e) => SynchronicityEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (lastDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
      return entries.where((e) => e.timestamp.isAfter(cutoffDate)).toList();
    }
    return entries;
  }
  
  // Pattern-Erkennung für wiederkehrende Zahlen
  Map<int, int> getSynchronicityNumberPatterns() {
    final entries = getSynchronicities();
    final patterns = <int, int>{};
    
    for (var entry in entries) {
      for (var number in entry.numbers) {
        patterns[number] = (patterns[number] ?? 0) + 1;
      }
    }
    
    return patterns;
  }
  
  // ============================================
  // VORSCHLAG 5: SPIRIT-JOURNAL
  // ============================================
  
  Future<void> saveJournalEntry(SpiritJournalEntry entry) async {
    final box = await _ensureBox(_journalEntriesBox);
    await box.put(entry.id, entry.toJson());
  }

  List<SpiritJournalEntry> getJournalEntries({String? category, int? lastDays}) {
    final box = _boxOrNull(_journalEntriesBox);
    if (box == null) return [];
    var entries = box.values
        .map((e) => SpiritJournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (category != null) {
      entries = entries.where((e) => e.category == category).toList();
    }

    if (lastDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
      entries = entries.where((e) => e.timestamp.isAfter(cutoffDate)).toList();
    }

    return entries..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  // ============================================
  // VORSCHLAG 6: PARTNER-PROFILE & KOMPATIBILITÄT
  // ============================================
  
  Future<void> savePartnerProfile(PartnerProfile partner) async {
    final box = await _ensureBox(_partnerProfilesBox);
    await box.put(partner.id, partner.toJson());
  }

  List<PartnerProfile> getPartnerProfiles() {
    final box = _boxOrNull(_partnerProfilesBox);
    if (box == null) return [];
    return box.values
        .map((e) => PartnerProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveCompatibilityAnalysis(CompatibilityAnalysis analysis) async {
    final box = await _ensureBox(_compatibilityBox);
    final key = '${analysis.userId}_${analysis.partnerId}';
    await box.put(key, analysis.toJson());
  }

  CompatibilityAnalysis? getCompatibilityAnalysis(String userId, String partnerId) {
    final box = _boxOrNull(_compatibilityBox);
    if (box == null) return null;
    final key = '${userId}_$partnerId';
    final data = box.get(key) as Map?;
    if (data == null) return null;
    return CompatibilityAnalysis.fromJson(Map<String, dynamic>.from(data));
  }
  
  // ============================================
  // VORSCHLAG 7: WOCHENHOROSKOP
  // ============================================
  
  Future<void> saveWeeklyHoroscope(WeeklyHoroscope horoscope) async {
    final box = await _ensureBox(_weeklyHoroscopeBox);
    final key = horoscope.weekStart.toIso8601String();
    await box.put(key, horoscope.toJson());
  }

  WeeklyHoroscope? getCurrentWeekHoroscope() {
    final box = _boxOrNull(_weeklyHoroscopeBox);
    if (box == null) return null;
    final now = DateTime.now();

    for (var entry in box.values) {
      final horoscope = WeeklyHoroscope.fromJson(Map<String, dynamic>.from(entry as Map));
      if (now.isAfter(horoscope.weekStart) && now.isBefore(horoscope.weekEnd)) {
        return horoscope;
      }
    }
    return null;
  }
  
  // ============================================
  // VORSCHLAG 8: GAMIFICATION - SPIRIT PROGRESS
  // ============================================
  
  Future<void> saveSpiritProgress(SpiritProgress progress) async {
    final box = await _ensureBox(_spiritProgressBox);
    await box.put('current_progress', progress.toJson());
  }

  SpiritProgress getSpiritProgress() {
    final box = _boxOrNull(_spiritProgressBox);
    if (box == null) return SpiritProgress.empty();
    final data = box.get('current_progress') as Map?;
    if (data == null) return SpiritProgress.empty();
    return SpiritProgress.fromJson(Map<String, dynamic>.from(data));
  }
  
  // Punkte hinzufügen und Progress aktualisieren
  Future<void> addPoints(int points, String activity) async {
    final progress = getSpiritProgress();
    final newTotalPoints = progress.totalPoints + points;
    
    // Level berechnen (alle 100 Punkte ein Level)
    final newLevel = (newTotalPoints / 100).floor() + 1;
    final pointsToNext = ((newLevel) * 100) - newTotalPoints;
    
    // Activity Count aktualisieren
    final newActivityCounts = Map<String, int>.from(progress.activityCounts);
    newActivityCounts[activity] = (newActivityCounts[activity] ?? 0) + 1;
    
    // Streak berechnen
    final now = DateTime.now();
    final lastActivity = progress.lastActivityDate;
    final daysSinceLastActivity = now.difference(lastActivity).inDays;
    
    int newStreak = progress.currentStreak;
    if (daysSinceLastActivity == 0) {
      // Heute schon aktiv
      newStreak = progress.currentStreak;
    } else if (daysSinceLastActivity == 1) {
      // Gestern aktiv → Streak erhöhen
      newStreak = progress.currentStreak + 1;
    } else {
      // Streak abgebrochen
      newStreak = 1;
    }
    
    final newLongestStreak = newStreak > progress.longestStreak 
        ? newStreak 
        : progress.longestStreak;
    
    final updatedProgress = SpiritProgress(
      totalPoints: newTotalPoints,
      currentLevel: newLevel,
      pointsToNextLevel: pointsToNext,
      unlockedAchievements: progress.unlockedAchievements,
      activityCounts: newActivityCounts,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
    );
    
    await saveSpiritProgress(updatedProgress);
  }
  
  
  // ═══════════════════════════════════════════════════════════
  // 🆕 TOP 10 VERBESSERUNGEN - STORAGE METHODS (v57)
  // ═══════════════════════════════════════════════════════════
  
  // ─────────────────────────────────────────────────────────
  // TAROT JOURNAL METHODS
  // ─────────────────────────────────────────────────────────
  
  Future<void> saveTarotReading(TarotReading reading) async {
    final box = await _ensureBox(_tarotReadingsBox);
    await box.put(reading.id, reading.toJson());
  }

  List<TarotReading> getAllTarotReadings() {
    final box = _boxOrNull(_tarotReadingsBox);
    if (box == null) return [];
    return box.values
        .map((e) => TarotReading.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> deleteTarotReading(String id) async {
    final box = await _ensureBox(_tarotReadingsBox);
    await box.delete(id);
  }
  
  // ─────────────────────────────────────────────────────────
  // MOON JOURNAL METHODS
  // ─────────────────────────────────────────────────────────
  
  Future<void> saveMoonJournalEntry(MoonJournalEntry entry) async {
    final box = await _ensureBox(_moonJournalBox);
    await box.put(entry.id, entry.toJson());
  }

  List<MoonJournalEntry> getAllMoonJournalEntries() {
    final box = _boxOrNull(_moonJournalBox);
    if (box == null) return [];
    return box.values
        .map((e) => MoonJournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  List<MoonJournalEntry> getMoonJournalEntriesByPhase(String phase) {
    return getAllMoonJournalEntries()
        .where((entry) => entry.moonPhase == phase)
        .toList();
  }
  
  // ─────────────────────────────────────────────────────────
  // CRYSTAL COLLECTION METHODS
  // ─────────────────────────────────────────────────────────
  
  Future<void> addCrystalToCollection(CrystalCollection crystal) async {
    final box = await _ensureBox(_crystalCollectionBox);
    await box.put(crystal.crystalName, crystal.toJson());
  }

  List<CrystalCollection> getMyCrystalCollection() {
    final box = _boxOrNull(_crystalCollectionBox);
    if (box == null) return [];
    return box.values
        .map((e) => CrystalCollection.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  bool isCrystalInCollection(String crystalName) {
    final box = _boxOrNull(_crystalCollectionBox);
    if (box == null) return false;
    return box.containsKey(crystalName);
  }
  
  Future<void> removeCrystalFromCollection(String crystalName) async {
    final box = await _ensureBox(_crystalCollectionBox);
    await box.delete(crystalName);
  }

  // ─────────────────────────────────────────────────────────
  // MANTRA CHALLENGE METHODS
  // ─────────────────────────────────────────────────────────

  Future<void> saveMantraChallenge(MantraChallenge challenge) async {
    final box = await _ensureBox(_mantraChallengesBox);
    await box.put(challenge.id, challenge.toJson());
  }

  List<MantraChallenge> getAllMantraChallenges() {
    final box = _boxOrNull(_mantraChallengesBox);
    if (box == null) return [];
    return box.values
        .map((e) => MantraChallenge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  
  MantraChallenge? getActiveMantraChallenge() {
    return getAllMantraChallenges()
        .where((c) => !c.isCompleted)
        .firstOrNull;
  }
  
  // ─────────────────────────────────────────────────────────
  // MEDITATION SESSION METHODS
  // ─────────────────────────────────────────────────────────
  
  Future<void> saveMeditationSession(MeditationSession session) async {
    final box = await _ensureBox(_meditationSessionsBox);
    await box.put(session.id, session.toJson());
  }

  List<MeditationSession> getAllMeditationSessions() {
    final box = _boxOrNull(_meditationSessionsBox);
    if (box == null) return [];
    return box.values
        .map((e) => MeditationSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getTotalMeditationMinutes() {
    return getAllMeditationSessions()
        .fold<int>(0, (sum, session) => sum + session.durationMinutes);
  }

  // ─────────────────────────────────────────────────────────
  // ACHIEVEMENT METHODS
  // ─────────────────────────────────────────────────────────

  Future<void> saveAppAchievement(AppAchievement achievement) async {
    final box = await _ensureBox(_achievementsBox);
    await box.put(achievement.id, achievement.toJson());
  }

  List<AppAchievement> getAllAppAchievements() {
    final box = _boxOrNull(_achievementsBox);
    if (box == null) return [];
    return box.values
        .map((e) => AppAchievement.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<AppAchievement> getUnlockedAppAchievements() {
    return getAllAppAchievements()
        .where((a) => a.isUnlocked)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }

  // ─────────────────────────────────────────────────────────
  // STREAK METHODS
  // ─────────────────────────────────────────────────────────

  Future<void> saveToolStreak(ToolStreak streak) async {
    final box = await _ensureBox(_toolStreaksBox);
    await box.put(streak.toolId, streak.toJson());
  }

  ToolStreak? getToolStreak(String toolId) {
    final box = _boxOrNull(_toolStreaksBox);
    if (box == null) return null;
    final data = box.get(toolId);
    if (data == null) return null;
    return ToolStreak.fromJson(Map<String, dynamic>.from(data as Map));
  }

  List<ToolStreak> getAllToolStreaks() {
    final box = _boxOrNull(_toolStreaksBox);
    if (box == null) return [];
    return box.values
        .map((e) => ToolStreak.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ============================================================================
  // ACHIEVEMENT METHODS (V115 MEGA UPDATE)
  // ============================================================================

  Future<Map<String, Map<String, dynamic>>> loadAchievementProgress() async {
    final box = await Hive.openBox('achievement_progress');
    final Map<String, Map<String, dynamic>> progress = {};
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) progress[key as String] = Map<String, dynamic>.from(data as Map);
    }
    return progress;
  }

  Future<void> saveAchievementProgress(String id, int progress, bool unlocked, DateTime? unlockedAt) async {
    final box = await Hive.openBox('achievement_progress');
    await box.put(id, {'achievementId': id, 'currentProgress': progress, 'isUnlocked': unlocked, 'unlockedAt': unlockedAt?.toIso8601String()});
  }

  Future<bool> unlockAchievement(String id) async {
    final box = await Hive.openBox('achievement_progress');
    final existing = box.get(id);
    if (existing != null && (existing as Map)['isUnlocked'] == true) return false;
    await box.put(id, {'achievementId': id, 'currentProgress': 0, 'isUnlocked': true, 'unlockedAt': DateTime.now().toIso8601String()});
    return true;
  }

  Future<void> incrementAchievementProgress(String id, int increment) async {
    final box = await Hive.openBox('achievement_progress');
    final existing = box.get(id);
    int current = existing != null ? (existing as Map)['currentProgress'] as int? ?? 0 : 0;
    await box.put(id, {'achievementId': id, 'currentProgress': current + increment, 'isUnlocked': false});
  }

  Future<bool> isAchievementUnlocked(String id) async {
    final box = await Hive.openBox('achievement_progress');
    final data = box.get(id);
    return data != null ? (data as Map)['isUnlocked'] as bool? ?? false : false;
  }

  Future<int> getUnlockedAchievementsCount() async {
    final box = await Hive.openBox('achievement_progress');
    return box.values.where((v) => (v as Map)['isUnlocked'] == true).length;
  }

  Future<int> getCurrentXP() async {
    final box = await Hive.openBox('user_progress');
    return box.get('xp', defaultValue: 0) as int;
  }

  Future<int> addXP(int amount) async {
    final box = await Hive.openBox('user_progress');
    final current = box.get('xp', defaultValue: 0) as int;
    final newXP = current + amount;
    await box.put('xp', newXP);
    return newXP;
  }

  // ============================================================================
  // MEDITATION & CHAKRA METHODS (V115 MEGA UPDATE)
  // ============================================================================

  Future<Map<String, int>> getMeditationStats() async {
    final box = await Hive.openBox('meditation_sessions');
    final sessions = box.values.toList();
    final totalSessions = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, session) {
      final data = session as Map;
      return sum + (data['duration'] as int? ?? 0);
    });
    final averageMinutes = totalSessions > 0 ? (totalMinutes / totalSessions).round() : 0;
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'averageMinutes': averageMinutes,
    };
  }

  Future<void> saveMeditationSessionComplete(Map<String, dynamic> session) async {
    final box = await Hive.openBox('meditation_sessions');
    final id = session['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, session);
  }

  Future<List<Map<String, dynamic>>> getCompletedMeditationSessions() async {
    final box = await Hive.openBox('meditation_sessions');
    return box.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getChakraJournalEntries() async {
    final box = await Hive.openBox('chakra_journal');
    return box.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  Future<void> saveChakraJournalEntry(Map<String, dynamic> entry) async {
    final box = await Hive.openBox('chakra_journal');
    final id = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, entry);
  }

  // ============================================================================
  // LEVEL & STREAK METHODS (V115 MEGA UPDATE)
  // ============================================================================

  Future<int> getCurrentLevel() async {
    final xp = await getCurrentXP();
    return _calculateLevel(xp);
  }

  int _calculateLevel(int xp) {
    if (xp < 100) return 1;
    return (math.sqrt(xp / 100)).floor() + 1;
  }

  Future<int> getXPForNextLevel() async {
    final currentLevel = await getCurrentLevel();
    final nextLevel = currentLevel + 1;
    return (nextLevel - 1) * (nextLevel - 1) * 100;
  }

  Future<double> getLevelProgress() async {
    final xp = await getCurrentXP();
    final currentLevel = await getCurrentLevel();
    final xpForCurrent = (currentLevel - 1) * (currentLevel - 1) * 100;
    final xpForNext = currentLevel * currentLevel * 100;
    final progress = (xp - xpForCurrent) / (xpForNext - xpForCurrent);
    return progress.clamp(0.0, 1.0);
  }

  Future<int> getCurrentStreak() async {
    final box = await Hive.openBox('user_progress');
    return box.get('current_streak', defaultValue: 0) as int;
  }

  Future<int> getBestStreak() async {
    final box = await Hive.openBox('user_progress');
    return box.get('best_streak', defaultValue: 0) as int;
  }

  Future<DateTime?> getLastCheckInDate() async {
    final box = await Hive.openBox('user_progress');
    final str = box.get('last_check_in_date') as String?;
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> incrementStreak() async {
    final box = await Hive.openBox('user_progress');
    final current = await getCurrentStreak();
    final newStreak = current + 1;
    await box.put('current_streak', newStreak);
    
    final best = await getBestStreak();
    if (newStreak > best) {
      await box.put('best_streak', newStreak);
    }
    
    await box.put('last_check_in_date', DateTime.now().toIso8601String());
  }

  Future<void> resetStreak() async {
    final box = await Hive.openBox('user_progress');
    await box.put('current_streak', 0);
  }

  // ════════════════════════════════════════════════════════════════
  // 🚀 TIER-1 MEGA UPGRADE METHODS (v44.1.0)
  // ════════════════════════════════════════════════════════════════
  
  // ────────────────────────────────────────────────────────────────
  // NUMEROLOGIE: PERSONAL YEAR JOURNEY MAP
  // ────────────────────────────────────────────────────────────────
  
  /// Personal Year Journey speichern
  Future<void> savePersonalYearJourney(Map<String, dynamic> journey) async {
    final box = await _ensureBox(_numerologyYearJourneyBox);
    final year = journey['year'] as int;
    await box.put(year, journey);
  }

  /// Personal Year Journey für ein bestimmtes Jahr laden
  Map<String, dynamic>? getPersonalYearJourney(int year) {
    final box = _boxOrNull(_numerologyYearJourneyBox);
    if (box == null) return null;
    final data = box.get(year);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  /// Numerologie Journal Eintrag speichern
  Future<void> saveNumerologyJournalEntry(Map<String, dynamic> entry) async {
    final box = await _ensureBox(_numerologyJournalBox);
    final id = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, entry);
  }

  /// Alle Numerologie Journal Einträge laden
  List<Map<String, dynamic>> getNumerologyJournalEntries() {
    final box = _boxOrNull(_numerologyJournalBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  /// Numerologie Meilenstein speichern
  Future<void> saveNumerologyMilestone(Map<String, dynamic> milestone) async {
    final box = await _ensureBox(_numerologyMilestonesBox);
    final id = milestone['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, milestone);
  }

  /// Alle Numerologie Meilensteine laden
  List<Map<String, dynamic>> getNumerologyMilestones() {
    final box = _boxOrNull(_numerologyMilestonesBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }
  
  // ────────────────────────────────────────────────────────────────
  // CHAKRA: BALANCE TRACKER
  // ────────────────────────────────────────────────────────────────
  
  /// Tägliche Chakra Scores speichern
  Future<void> saveChakraDailyScores(Map<String, dynamic> scores) async {
    final box = await _ensureBox(_chakraDailyScoresBox);
    final date = scores['date'] as String;
    await box.put(date, scores);
  }

  /// Chakra Scores für ein bestimmtes Datum laden
  Map<String, dynamic>? getChakraDailyScores(DateTime date) {
    final box = _boxOrNull(_chakraDailyScoresBox);
    if (box == null) return null;
    final dateStr = date.toIso8601String().split('T')[0];
    final data = box.get(dateStr);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  /// Letzte 30 Tage Chakra History laden
  List<Map<String, dynamic>> getChakraHistory(int days) {
    final box = _boxOrNull(_chakraDailyScoresBox);
    if (box == null) return [];
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((entry) {
          final date = DateTime.parse(entry['date'] as String);
          return date.isAfter(cutoff);
        })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Chakra Meditation Session speichern
  Future<void> saveChakraMeditationSession(Map<String, dynamic> session) async {
    final box = await _ensureBox(_chakraMeditationSessionsBox);
    final id = session['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, session);
  }

  /// Alle Chakra Meditation Sessions laden
  List<Map<String, dynamic>> getChakraMeditationSessions() {
    final box = _boxOrNull(_chakraMeditationSessionsBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  /// Chakra Affirmation speichern
  Future<void> saveChakraAffirmation(Map<String, dynamic> affirmation) async {
    final box = await _ensureBox(_chakraAffirmationsBox);
    final id = affirmation['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, affirmation);
  }

  /// Alle Chakra Affirmationen laden
  List<Map<String, dynamic>> getChakraAffirmations() {
    final box = _boxOrNull(_chakraAffirmationsBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  
  // ────────────────────────────────────────────────────────────────
  // MEDITATION-TIMER: UPGRADE
  // ────────────────────────────────────────────────────────────────
  
  /// Enhanced Meditation Session speichern
  Future<void> saveEnhancedMeditationSession(Map<String, dynamic> session) async {
    final box = await _ensureBox(_meditationSessionsEnhancedBox);
    final id = session['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, session);
  }

  /// Alle Enhanced Meditation Sessions laden
  List<Map<String, dynamic>> getEnhancedMeditationSessions() {
    final box = _boxOrNull(_meditationSessionsEnhancedBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  /// Meditation Preset speichern
  Future<void> saveMeditationPreset(Map<String, dynamic> preset) async {
    final box = await _ensureBox(_meditationPresetsBox);
    final id = preset['id'] ?? preset['name'] as String;
    await box.put(id, preset);
  }

  /// Alle Meditation Presets laden
  List<Map<String, dynamic>> getMeditationPresets() {
    final box = _boxOrNull(_meditationPresetsBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  
  /// Meditation Streak berechnen
  int getMeditationStreak() {
    final sessions = getEnhancedMeditationSessions();
    if (sessions.isEmpty) return 0;
    
    int streak = 0;
    DateTime? lastDate;
    
    for (var session in sessions.reversed) {
      final date = DateTime.parse(session['timestamp'] as String);
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      if (lastDate == null) {
        lastDate = dateOnly;
        streak = 1;
      } else {
        final diff = lastDate.difference(dateOnly).inDays;
        if (diff == 1) {
          streak++;
          lastDate = dateOnly;
        } else if (diff > 1) {
          break;
        }
      }
    }
    
    return streak;
  }
  
  // ────────────────────────────────────────────────────────────────
  // TAROT-READER: NEUES TOOL
  // ────────────────────────────────────────────────────────────────
  
  /// Daily Tarot Card speichern
  Future<void> saveTarotDailyCard(Map<String, dynamic> card) async {
    final box = await _ensureBox(_tarotDailyCardsBox);
    final date = card['date'] as String;
    await box.put(date, card);
  }

  /// Daily Tarot Card für heute laden
  Map<String, dynamic>? getTodaysTarotCard() {
    final box = _boxOrNull(_tarotDailyCardsBox);
    if (box == null) return null;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = box.get(today);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  /// Tarot Spread speichern
  Future<void> saveTarotSpread(Map<String, dynamic> spread) async {
    final box = await _ensureBox(_tarotSpreadsBox);
    final id = spread['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, spread);
  }

  /// Alle Tarot Spreads laden
  List<Map<String, dynamic>> getTarotSpreads() {
    final box = _boxOrNull(_tarotSpreadsBox);
    if (box == null) return [];
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  /// Tarot Spread löschen
  Future<void> deleteTarotSpread(String id) async {
    final box = await _ensureBox(_tarotSpreadsBox);
    await box.delete(id);
  }
  
  // ────────────────────────────────────────────────────────────────
  // ✅ NEU: ADMIN-SYSTEM ROLLEN-VERWALTUNG
  // ────────────────────────────────────────────────────────────────
  
  /// Get Username für eine Welt
  Future<String?> getUsername(String world) async {
    if (world == 'materie') {
      final profile = getMaterieProfile();
      return profile?.username;
    } else if (world == 'energie') {
      final profile = getEnergieProfile();
      return profile?.username;
    }
    return null;
  }
  
  /// Get User ID für eine Welt
  Future<String?> getUserId(String world) async {
    if (world == 'materie') {
      final profile = getMaterieProfile();
      return profile?.userId;
    } else if (world == 'energie') {
      final profile = getEnergieProfile();
      return profile?.userId;
    }
    return null;
  }
  
  /// Get Rolle für eine Welt
  Future<String?> getRole(String world) async {
    if (world == 'materie') {
      final profile = getMaterieProfile();
      return profile?.role;
    } else if (world == 'energie') {
      final profile = getEnergieProfile();
      return profile?.role;
    }
    return null;
  }
  
  /// Prüfe ob User Admin ist (admin oder root_admin)
  Future<bool> isAdmin(String world) async {
    if (world == 'materie') {
      final profile = getMaterieProfile();
      return profile?.isAdmin() ?? false;
    } else if (world == 'energie') {
      final profile = getEnergieProfile();
      return profile?.isAdmin() ?? false;
    }
    return false;
  }
  
  /// Prüfe ob User Root-Admin ist
  Future<bool> isRootAdmin(String world) async {
    if (world == 'materie') {
      final profile = getMaterieProfile();
      return profile?.isRootAdmin() ?? false;
    } else if (world == 'energie') {
      final profile = getEnergieProfile();
      return profile?.isRootAdmin() ?? false;
    }
    return false;
  }
  
  /// Get effective Role (mit Default 'user')
  Future<String> getEffectiveRole(String world) async {
    if (world == 'materie') {
      final profile = getMaterieProfile();
      return profile?.effectiveRole ?? 'user';
    } else if (world == 'energie') {
      final profile = getEnergieProfile();
      return profile?.effectiveRole ?? 'user';
    }
    return 'user';
  }
  
  /// 🔧 STUB: Get Data from generic key (for DynamicContentService)
  Future<String?> getData(String key) async {
    return await guardStorage(
      () async {
        final box = await getBox('app_cache');
        return box.get(key);
      },
      operation: 'getData',
      key: key,
      onError: (e, stack) async => null,
    );
  }
  
  /// 🔧 STUB: Save Data to generic key (for DynamicContentService)
  Future<void> saveData(String key, String value) async {
    await guardStorage(
      () async {
        final box = await getBox('app_cache');
        await box.put(key, value);
      },
      operation: 'saveData',
      key: key,
    );
  }
}
