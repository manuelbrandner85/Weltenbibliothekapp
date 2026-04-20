import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import '../models/spirit_profile.dart';
import '../models/research_topic.dart';
import '../models/spirit_entry.dart';
import '../models/community_post.dart';
import '../models/spirit_extended_models.dart';
import '../models/app_data.dart';
import '../core/exceptions/exception_guard.dart';
import 'cloud_tool_data_service.dart';
import 'sqlite_storage_service.dart';

/// Lokaler Storage Service (SQLite via SqliteStorageService)
/// Für offline-first Funktionalität
class StorageService {
  // Box-Namen
  static const String _materieProfileBox = 'materie_profiles';
  static const String _energieProfileBox = 'energie_profiles';
  static const String _researchTopicsBox = 'research_topics';
  static const String _spiritEntriesBox = 'spirit_entries';
  static const String _communityPostsBox = 'community_posts';
  static const String _dailyPracticesBox = 'daily_practices';
  static const String _synchronicityBox = 'synchronicity_entries';
  static const String _journalEntriesBox = 'journal_entries';
  static const String _partnerProfilesBox = 'partner_profiles';
  static const String _compatibilityBox = 'compatibility_analyses';
  static const String _weeklyHoroscopeBox = 'weekly_horoscope';
  static const String _spiritProgressBox = 'spirit_progress';
  static const String _tarotReadingsBox = 'tarot_readings';
  static const String _moonJournalBox = 'moon_journal';
  static const String _crystalCollectionBox = 'crystal_collection';
  static const String _mantraChallengesBox = 'mantra_challenges';
  static const String _meditationSessionsBox = 'meditation_sessions';
  static const String _achievementsBox = 'achievements';
  static const String _toolStreaksBox = 'tool_streaks';
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
  static const String _postDraftsBox = 'post_drafts'; // ignore: unused_field
  static const String _scheduledPostsBox = 'scheduled_posts'; // ignore: unused_field

  // ─── SharedPreferences keys (Profile-Speicher) ──────────────────────────────
  static const String _kMaterieProfile = 'sp_materie_profile';
  static const String _kEnergieProfile = 'sp_energie_profile';
  static const String _kSpiritProfile  = 'sp_spirit_profile';

  // Singleton Pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  Future<SharedPreferences> _ensurePrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  // Kurzreferenz auf SQLite-Service
  final SqliteStorageService _db = SqliteStorageService.instance;

  /// Initialisierung (SharedPreferences — SQLite wird in main.dart initialisiert)
  Future<void> init() async {
    if (kDebugMode) debugPrint('📦 Storage: Initialisierung starten...');
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) debugPrint('✅ Storage: Bereit (Profile via SharedPreferences, Daten via SQLite)');
  }

  /// Hive-kompatibler Box-Shim (Hive→sqflite Migration).
  /// Legacy-Caller (auto_save_manager, gematria_calculator, create_post_dialog)
  /// erwarten `StorageService().getBox(name)` mit Hive-Box-API (put/get/values/...).
  /// Siehe BoxShim in sqlite_storage_service.dart.
  Future<BoxShim> getBox(String boxName) async => BoxShim(boxName);

  /// Synchrone Variante für Caller die keinen await nutzen können.
  BoxShim getBoxSync(String boxName) => BoxShim(boxName);

  // ============================================
  // CLOUD-SYNC (Fire-and-forget Supabase-Mirror)
  // ============================================

  void _cloudSync(String toolKey, String itemId, Map<String, dynamic> data) {
    unawaited(
      CloudToolDataService.instance.upsert(
        toolKey: toolKey,
        itemId: itemId,
        data: data,
      ),
    );
  }

  void _cloudDelete(String toolKey, String itemId) {
    unawaited(
      CloudToolDataService.instance.delete(toolKey: toolKey, itemId: itemId),
    );
  }

  // ============================================
  // MATERIE PROFILE — SharedPreferences
  // ============================================

  Future<void> saveMaterieProfile(MaterieProfile profile) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_kMaterieProfile, jsonEncode(profile.toJson()));
  }

  MaterieProfile? getMaterieProfile() {
    final raw = _prefs?.getString(_kMaterieProfile);
    if (raw == null) return null;
    try {
      return MaterieProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<MaterieProfile?> loadMaterieProfile() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_kMaterieProfile);
    if (raw == null) return null;
    try {
      return MaterieProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<void> deleteMaterieProfile() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_kMaterieProfile);
  }

  // ============================================
  // ENERGIE PROFILE — SharedPreferences
  // ============================================

  Future<void> saveEnergieProfile(EnergieProfile profile) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_kEnergieProfile, jsonEncode(profile.toJson()));
  }

  EnergieProfile? getEnergieProfile() {
    final raw = _prefs?.getString(_kEnergieProfile);
    if (raw == null) return null;
    try {
      return EnergieProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<EnergieProfile?> loadEnergieProfile() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_kEnergieProfile);
    if (raw == null) return null;
    try {
      return EnergieProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<void> deleteEnergieProfile() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_kEnergieProfile);
  }

  // ============================================
  // SPIRIT PROFILE — SharedPreferences
  // ============================================

  SpiritProfile? getSpiritProfile() {
    final raw = _prefs?.getString(_kSpiritProfile) ?? _prefs?.getString(_kEnergieProfile);
    if (raw == null) return null;
    try {
      return SpiritProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<void> saveSpiritProfile(SpiritProfile profile) async {
    final prefs = await _ensurePrefs();
    final json = jsonEncode(profile.toJson());
    await prefs.setString(_kSpiritProfile, json);
    await prefs.setString(_kEnergieProfile, json);
    if (kDebugMode) debugPrint('✅ Spirit profile saved (SharedPreferences)');
  }

  Future<SpiritProfile?> loadSpiritProfile() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_kSpiritProfile) ?? prefs.getString(_kEnergieProfile);
    if (raw == null) return null;
    try {
      return SpiritProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  // ============================================
  // RESEARCH TOPICS (MATERIE)
  // ============================================

  Future<void> saveResearchTopic(ResearchTopic topic) async {
    await _db.put(_researchTopicsBox, topic.id, topic.toJson());
  }

  List<ResearchTopic> getResearchTopics() {
    return _db.getAllSync(_researchTopicsBox)
        .map((e) => ResearchTopic.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ResearchTopic>> getAllResearchTopics() async {
    return getResearchTopics();
  }

  // ============================================
  // SPIRIT ENTRIES (ENERGIE)
  // ============================================

  Future<void> saveSpiritEntry(SpiritEntry entry) async {
    await _db.put(_spiritEntriesBox, entry.id, entry.toJson());
    _cloudSync(_spiritEntriesBox, entry.id, entry.toJson());
  }

  List<SpiritEntry> getSpiritEntries() {
    return _db.getAllSync(_spiritEntriesBox)
        .map((e) => SpiritEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SpiritEntry>> getAllSpiritEntries() async {
    return getSpiritEntries();
  }

  // ============================================
  // COMMUNITY POSTS (beide Welten)
  // ============================================

  Future<void> saveCommunityPost(CommunityPost post) async {
    await _db.put(_communityPostsBox, post.id, post.toJson());
  }

  List<CommunityPost> getCommunityPosts(WorldType worldType) {
    return _db.getAllSync(_communityPostsBox)
        .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((post) => post.worldType == worldType)
        .toList();
  }

  // ============================================
  // UTILITY
  // ============================================

  Future<void> clearAll() async {
    await _db.clear(_materieProfileBox);
    await _db.clear(_energieProfileBox);
    await _db.clear(_researchTopicsBox);
    await _db.clear(_spiritEntriesBox);
    await _db.clear(_communityPostsBox);
  }

  // ============================================
  // TÄGLICHE SPIRIT-ÜBUNGEN
  // ============================================

  Future<void> saveDailyPractice(DailySpiritPractice practice) async {
    await _db.put(_dailyPracticesBox, practice.id, practice.toJson());
  }

  List<DailySpiritPractice> getDailyPractices({DateTime? forDate}) {
    final practices = _db.getAllSync(_dailyPracticesBox)
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
  // SYNCHRONIZITÄTS-TRACKER
  // ============================================

  Future<void> saveSynchronicity(SynchronicityEntry entry) async {
    await _db.put(_synchronicityBox, entry.id, entry.toJson());
    _cloudSync(_synchronicityBox, entry.id, entry.toJson());
  }

  List<SynchronicityEntry> getSynchronicities({int? lastDays}) {
    final entries = _db.getAllSync(_synchronicityBox)
        .map((e) => SynchronicityEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (lastDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
      return entries.where((e) => e.timestamp.isAfter(cutoffDate)).toList();
    }
    return entries;
  }

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
  // SPIRIT-JOURNAL
  // ============================================

  Future<void> saveJournalEntry(SpiritJournalEntry entry) async {
    await _db.put(_journalEntriesBox, entry.id, entry.toJson());
    _cloudSync(_journalEntriesBox, entry.id, entry.toJson());
  }

  List<SpiritJournalEntry> getJournalEntries({String? category, int? lastDays}) {
    var entries = _db.getAllSync(_journalEntriesBox)
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
  // PARTNER-PROFILE & KOMPATIBILITÄT
  // ============================================

  Future<void> savePartnerProfile(PartnerProfile partner) async {
    await _db.put(_partnerProfilesBox, partner.id, partner.toJson());
    _cloudSync(_partnerProfilesBox, partner.id, partner.toJson());
  }

  List<PartnerProfile> getPartnerProfiles() {
    return _db.getAllSync(_partnerProfilesBox)
        .map((e) => PartnerProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveCompatibilityAnalysis(CompatibilityAnalysis analysis) async {
    final key = '${analysis.userId}_${analysis.partnerId}';
    await _db.put(_compatibilityBox, key, analysis.toJson());
    _cloudSync(_compatibilityBox, key, analysis.toJson());
  }

  CompatibilityAnalysis? getCompatibilityAnalysis(String userId, String partnerId) {
    final key = '${userId}_$partnerId';
    final data = _db.getSync(_compatibilityBox, key) as Map?;
    if (data == null) return null;
    return CompatibilityAnalysis.fromJson(Map<String, dynamic>.from(data));
  }

  // ============================================
  // WOCHENHOROSKOP
  // ============================================

  Future<void> saveWeeklyHoroscope(WeeklyHoroscope horoscope) async {
    final key = horoscope.weekStart.toIso8601String();
    await _db.put(_weeklyHoroscopeBox, key, horoscope.toJson());
  }

  WeeklyHoroscope? getCurrentWeekHoroscope() {
    final now = DateTime.now();
    for (var entry in _db.getAllSync(_weeklyHoroscopeBox)) {
      final horoscope = WeeklyHoroscope.fromJson(Map<String, dynamic>.from(entry as Map));
      if (now.isAfter(horoscope.weekStart) && now.isBefore(horoscope.weekEnd)) {
        return horoscope;
      }
    }
    return null;
  }

  // ============================================
  // GAMIFICATION - SPIRIT PROGRESS
  // ============================================

  Future<void> saveSpiritProgress(SpiritProgress progress) async {
    await _db.put(_spiritProgressBox, 'current_progress', progress.toJson());
    _cloudSync(_spiritProgressBox, 'current_progress', progress.toJson());
  }

  SpiritProgress getSpiritProgress() {
    final data = _db.getSync(_spiritProgressBox, 'current_progress') as Map?;
    if (data == null) return SpiritProgress.empty();
    return SpiritProgress.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> addPoints(int points, String activity) async {
    final progress = getSpiritProgress();
    final newTotalPoints = progress.totalPoints + points;
    final newLevel = (newTotalPoints / 100).floor() + 1;
    final pointsToNext = ((newLevel) * 100) - newTotalPoints;
    final newActivityCounts = Map<String, int>.from(progress.activityCounts);
    newActivityCounts[activity] = (newActivityCounts[activity] ?? 0) + 1;
    final now = DateTime.now();
    final lastActivity = progress.lastActivityDate;
    final daysSinceLastActivity = now.difference(lastActivity).inDays;
    int newStreak = progress.currentStreak;
    if (daysSinceLastActivity == 1) {
      newStreak = progress.currentStreak + 1;
    } else if (daysSinceLastActivity > 1) {
      newStreak = 1;
    }
    final newLongestStreak = newStreak > progress.longestStreak
        ? newStreak
        : progress.longestStreak;
    await saveSpiritProgress(SpiritProgress(
      totalPoints: newTotalPoints,
      currentLevel: newLevel,
      pointsToNextLevel: pointsToNext,
      unlockedAchievements: progress.unlockedAchievements,
      activityCounts: newActivityCounts,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // TAROT JOURNAL
  // ═══════════════════════════════════════════════════════════

  Future<void> saveTarotReading(TarotReading reading) async {
    await _db.put(_tarotReadingsBox, reading.id, reading.toJson());
  }

  List<TarotReading> getAllTarotReadings() {
    return _db.getAllSync(_tarotReadingsBox)
        .map((e) => TarotReading.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> deleteTarotReading(String id) async {
    await _db.delete(_tarotReadingsBox, id);
  }

  // ═══════════════════════════════════════════════════════════
  // MOON JOURNAL
  // ═══════════════════════════════════════════════════════════

  Future<void> saveMoonJournalEntry(MoonJournalEntry entry) async {
    await _db.put(_moonJournalBox, entry.id, entry.toJson());
  }

  List<MoonJournalEntry> getAllMoonJournalEntries() {
    return _db.getAllSync(_moonJournalBox)
        .map((e) => MoonJournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<MoonJournalEntry> getMoonJournalEntriesByPhase(String phase) {
    return getAllMoonJournalEntries()
        .where((entry) => entry.moonPhase == phase)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════
  // CRYSTAL COLLECTION
  // ═══════════════════════════════════════════════════════════

  Future<void> addCrystalToCollection(CrystalCollection crystal) async {
    await _db.put(_crystalCollectionBox, crystal.crystalName, crystal.toJson());
    _cloudSync(_crystalCollectionBox, crystal.crystalName, crystal.toJson());
  }

  List<CrystalCollection> getMyCrystalCollection() {
    return _db.getAllSync(_crystalCollectionBox)
        .map((e) => CrystalCollection.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  bool isCrystalInCollection(String crystalName) {
    return _db.containsKeySync(_crystalCollectionBox, crystalName);
  }

  Future<void> removeCrystalFromCollection(String crystalName) async {
    await _db.delete(_crystalCollectionBox, crystalName);
    _cloudDelete(_crystalCollectionBox, crystalName);
  }

  // ═══════════════════════════════════════════════════════════
  // MANTRA CHALLENGE
  // ═══════════════════════════════════════════════════════════

  Future<void> saveMantraChallenge(MantraChallenge challenge) async {
    await _db.put(_mantraChallengesBox, challenge.id, challenge.toJson());
    _cloudSync(_mantraChallengesBox, challenge.id, challenge.toJson());
  }

  List<MantraChallenge> getAllMantraChallenges() {
    return _db.getAllSync(_mantraChallengesBox)
        .map((e) => MantraChallenge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  MantraChallenge? getActiveMantraChallenge() {
    return getAllMantraChallenges().where((c) => !c.isCompleted).firstOrNull;
  }

  // ═══════════════════════════════════════════════════════════
  // MEDITATION SESSION
  // ═══════════════════════════════════════════════════════════

  Future<void> saveMeditationSession(MeditationSession session) async {
    await _db.put(_meditationSessionsBox, session.id, session.toJson());
  }

  List<MeditationSession> getAllMeditationSessions() {
    return _db.getAllSync(_meditationSessionsBox)
        .map((e) => MeditationSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getTotalMeditationMinutes() {
    return getAllMeditationSessions()
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // ═══════════════════════════════════════════════════════════
  // ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> saveAppAchievement(AppAchievement achievement) async {
    await _db.put(_achievementsBox, achievement.id, achievement.toJson());
  }

  List<AppAchievement> getAllAppAchievements() {
    return _db.getAllSync(_achievementsBox)
        .map((e) => AppAchievement.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<AppAchievement> getUnlockedAppAchievements() {
    return getAllAppAchievements()
        .where((a) => a.isUnlocked)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }

  // ═══════════════════════════════════════════════════════════
  // STREAK METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> saveToolStreak(ToolStreak streak) async {
    await _db.put(_toolStreaksBox, streak.toolId, streak.toJson());
    _cloudSync(_toolStreaksBox, streak.toolId, streak.toJson());
  }

  ToolStreak? getToolStreak(String toolId) {
    final data = _db.getSync(_toolStreaksBox, toolId);
    if (data == null) return null;
    return ToolStreak.fromJson(Map<String, dynamic>.from(data as Map));
  }

  List<ToolStreak> getAllToolStreaks() {
    return _db.getAllSync(_toolStreaksBox)
        .map((e) => ToolStreak.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════
  // ACHIEVEMENT PROGRESS (V115)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, Map<String, dynamic>>> loadAchievementProgress() async {
    final all = await _db.getAllWithKeys('achievement_progress');
    return all.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  Future<void> saveAchievementProgress(
      String id, int progress, bool unlocked, DateTime? unlockedAt) async {
    await _db.put('achievement_progress', id, {
      'achievementId': id,
      'currentProgress': progress,
      'isUnlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    });
  }

  Future<bool> unlockAchievement(String id) async {
    final existing = _db.getSync('achievement_progress', id) as Map?;
    if (existing != null && existing['isUnlocked'] == true) return false;
    await _db.put('achievement_progress', id, {
      'achievementId': id,
      'currentProgress': 0,
      'isUnlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<void> incrementAchievementProgress(String id, int increment) async {
    final existing = _db.getSync('achievement_progress', id) as Map?;
    final current = existing != null
        ? (existing['currentProgress'] as int? ?? 0)
        : 0;
    await _db.put('achievement_progress', id, {
      'achievementId': id,
      'currentProgress': current + increment,
      'isUnlocked': false,
    });
  }

  Future<bool> isAchievementUnlocked(String id) async {
    final data = _db.getSync('achievement_progress', id) as Map?;
    return data != null ? (data['isUnlocked'] as bool? ?? false) : false;
  }

  Future<int> getUnlockedAchievementsCount() async {
    return _db.getAllSync('achievement_progress')
        .where((v) => (v as Map)['isUnlocked'] == true)
        .length;
  }

  Future<int> getCurrentXP() async {
    return (_db.getSync('user_progress', 'xp') as int?) ?? 0;
  }

  Future<int> addXP(int amount) async {
    final current = (_db.getSync('user_progress', 'xp') as int?) ?? 0;
    final newXP = current + amount;
    await _db.put('user_progress', 'xp', newXP);
    return newXP;
  }

  // ═══════════════════════════════════════════════════════════
  // MEDITATION & CHAKRA (V115)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, int>> getMeditationStats() async {
    final sessions = _db.getAllSync('meditation_sessions');
    final totalSessions = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, s) {
      return sum + ((s as Map)['duration'] as int? ?? 0);
    });
    final averageMinutes =
        totalSessions > 0 ? (totalMinutes / totalSessions).round() : 0;
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'averageMinutes': averageMinutes,
    };
  }

  Future<void> saveMeditationSessionComplete(
      Map<String, dynamic> session) async {
    final id = session['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _db.put('meditation_sessions', id, session);
  }

  Future<List<Map<String, dynamic>>> getCompletedMeditationSessions() async {
    return _db
        .getAllSync('meditation_sessions')
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getChakraJournalEntries() async {
    return _db
        .getAllSync('chakra_journal')
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<void> saveChakraJournalEntry(Map<String, dynamic> entry) async {
    final id = entry['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _db.put('chakra_journal', id, entry);
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL & STREAK (V115)
  // ═══════════════════════════════════════════════════════════

  Future<int> getCurrentLevel() async {
    return _calculateLevel(await getCurrentXP());
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
    return ((xp - xpForCurrent) / (xpForNext - xpForCurrent)).clamp(0.0, 1.0);
  }

  Future<int> getCurrentStreak() async {
    return (_db.getSync('user_progress', 'current_streak') as int?) ?? 0;
  }

  Future<int> getBestStreak() async {
    return (_db.getSync('user_progress', 'best_streak') as int?) ?? 0;
  }

  Future<DateTime?> getLastCheckInDate() async {
    final str = _db.getSync('user_progress', 'last_check_in_date') as String?;
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> incrementStreak() async {
    final current = await getCurrentStreak();
    final newStreak = current + 1;
    await _db.put('user_progress', 'current_streak', newStreak);
    final best = await getBestStreak();
    if (newStreak > best) {
      await _db.put('user_progress', 'best_streak', newStreak);
    }
    await _db.put('user_progress', 'last_check_in_date',
        DateTime.now().toIso8601String());
  }

  Future<void> resetStreak() async {
    await _db.put('user_progress', 'current_streak', 0);
  }

  // ═══════════════════════════════════════════════════════════
  // NUMEROLOGIE: PERSONAL YEAR JOURNEY
  // ═══════════════════════════════════════════════════════════

  Future<void> savePersonalYearJourney(Map<String, dynamic> journey) async {
    final year = journey['year'] as int;
    await _db.put(_numerologyYearJourneyBox, year.toString(), journey);
    _cloudSync(_numerologyYearJourneyBox, year.toString(), journey);
  }

  Map<String, dynamic>? getPersonalYearJourney(int year) {
    final data = _db.getSync(_numerologyYearJourneyBox, year.toString());
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  Future<void> saveNumerologyJournalEntry(Map<String, dynamic> entry) async {
    final id = (entry['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    await _db.put(_numerologyJournalBox, id, entry);
    _cloudSync(_numerologyJournalBox, id, entry);
  }

  List<Map<String, dynamic>> getNumerologyJournalEntries() {
    return _db.getAllSync(_numerologyJournalBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  Future<void> saveNumerologyMilestone(Map<String, dynamic> milestone) async {
    final id = (milestone['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    await _db.put(_numerologyMilestonesBox, id, milestone);
    _cloudSync(_numerologyMilestonesBox, id, milestone);
  }

  List<Map<String, dynamic>> getNumerologyMilestones() {
    return _db.getAllSync(_numerologyMilestonesBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) =>
          (a['date'] as String).compareTo(b['date'] as String));
  }

  // ═══════════════════════════════════════════════════════════
  // CHAKRA: BALANCE TRACKER
  // ═══════════════════════════════════════════════════════════

  Future<void> saveChakraDailyScores(Map<String, dynamic> scores) async {
    final date = scores['date'] as String;
    await _db.put(_chakraDailyScoresBox, date, scores);
    _cloudSync(_chakraDailyScoresBox, date, scores);
  }

  Map<String, dynamic>? getChakraDailyScores(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = _db.getSync(_chakraDailyScoresBox, dateStr);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  List<Map<String, dynamic>> getChakraHistory(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _db.getAllSync(_chakraDailyScoresBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((entry) => DateTime.parse(entry['date'] as String).isAfter(cutoff))
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  Future<void> saveChakraMeditationSession(Map<String, dynamic> session) async {
    final id = (session['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    await _db.put(_chakraMeditationSessionsBox, id, session);
    _cloudSync(_chakraMeditationSessionsBox, id, session);
  }

  List<Map<String, dynamic>> getChakraMeditationSessions() {
    return _db.getAllSync(_chakraMeditationSessionsBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  Future<void> saveChakraAffirmation(Map<String, dynamic> affirmation) async {
    final id = (affirmation['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    await _db.put(_chakraAffirmationsBox, id, affirmation);
    _cloudSync(_chakraAffirmationsBox, id, affirmation);
  }

  List<Map<String, dynamic>> getChakraAffirmations() {
    return _db.getAllSync(_chakraAffirmationsBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════
  // MEDITATION-TIMER: ENHANCED
  // ═══════════════════════════════════════════════════════════

  Future<void> saveEnhancedMeditationSession(Map<String, dynamic> session) async {
    final id = (session['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    await _db.put(_meditationSessionsEnhancedBox, id, session);
    _cloudSync(_meditationSessionsEnhancedBox, id, session);
  }

  List<Map<String, dynamic>> getEnhancedMeditationSessions() {
    return _db.getAllSync(_meditationSessionsEnhancedBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  Future<void> saveMeditationPreset(Map<String, dynamic> preset) async {
    final id = (preset['id'] ?? preset['name'] as String).toString();
    await _db.put(_meditationPresetsBox, id, preset);
    _cloudSync(_meditationPresetsBox, id, preset);
  }

  List<Map<String, dynamic>> getMeditationPresets() {
    return _db.getAllSync(_meditationPresetsBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

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

  // ═══════════════════════════════════════════════════════════
  // TAROT-READER
  // ═══════════════════════════════════════════════════════════

  Future<void> saveTarotDailyCard(Map<String, dynamic> card) async {
    final date = card['date'] as String;
    await _db.put(_tarotDailyCardsBox, date, card);
    _cloudSync(_tarotDailyCardsBox, date, card);
  }

  Map<String, dynamic>? getTodaysTarotCard() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = _db.getSync(_tarotDailyCardsBox, today);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  Future<void> saveTarotSpread(Map<String, dynamic> spread) async {
    final id = (spread['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    await _db.put(_tarotSpreadsBox, id, spread);
    _cloudSync(_tarotSpreadsBox, id, spread);
  }

  List<Map<String, dynamic>> getTarotSpreads() {
    return _db.getAllSync(_tarotSpreadsBox)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  Future<void> deleteTarotSpread(String id) async {
    await _db.delete(_tarotSpreadsBox, id);
    _cloudDelete(_tarotSpreadsBox, id);
  }

  // ═══════════════════════════════════════════════════════════
  // ADMIN-SYSTEM ROLLEN-VERWALTUNG
  // ═══════════════════════════════════════════════════════════

  Future<String?> getUsername(String world) async {
    if (world == 'materie') return getMaterieProfile()?.username;
    if (world == 'energie') return getEnergieProfile()?.username;
    return null;
  }

  Future<String?> getUserId(String world) async {
    if (world == 'materie') return getMaterieProfile()?.userId;
    if (world == 'energie') return getEnergieProfile()?.userId;
    return null;
  }

  Future<String?> getRole(String world) async {
    if (world == 'materie') return getMaterieProfile()?.role;
    if (world == 'energie') return getEnergieProfile()?.role;
    return null;
  }

  Future<bool> isAdmin(String world) async {
    if (world == 'materie') return getMaterieProfile()?.isAdmin() ?? false;
    if (world == 'energie') return getEnergieProfile()?.isAdmin() ?? false;
    return false;
  }

  Future<bool> isRootAdmin(String world) async {
    if (world == 'materie') return getMaterieProfile()?.isRootAdmin() ?? false;
    if (world == 'energie') return getEnergieProfile()?.isRootAdmin() ?? false;
    return false;
  }

  Future<String> getEffectiveRole(String world) async {
    if (world == 'materie') return getMaterieProfile()?.effectiveRole ?? 'user';
    if (world == 'energie') return getEnergieProfile()?.effectiveRole ?? 'user';
    return 'user';
  }

  // ═══════════════════════════════════════════════════════════
  // GENERIC KEY-VALUE (DynamicContentService)
  // ═══════════════════════════════════════════════════════════

  Future<String?> getData(String key) async {
    return await guardStorage(
      () async {
        final v = _db.getSync('app_cache', key);
        return v as String?;
      },
      operation: 'getData',
      key: key,
      onError: (e, stack) async => null,
    );
  }

  Future<void> saveData(String key, String value) async {
    await guardStorage(
      () => _db.put('app_cache', key, value),
      operation: 'saveData',
      key: key,
    );
  }
}
