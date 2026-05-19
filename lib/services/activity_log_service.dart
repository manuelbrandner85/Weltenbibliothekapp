// ActivityLogService -- zentrale Stelle fuer Echtzeit-User-Aktionen.
//
// Konsolidiert was bisher verstreut war:
// - StreakTrackingService.trackToolUsage()  (+5 Punkte lokal)
// - AchievementService.incrementProgress()  (Achievement-Fortschritt)
// - Profile/User-Aktionen (Chat-Nachricht, Mood-Update, Profil-Edit)
//
// Jede log*-Methode emittiert ein Activity-Event ueber den Stream, damit
// UI (Badges, Confetti, In-App-Toasts) reaktiv reagieren kann.
//
// Tracking ist lokal-first (SharedPreferences) und feuert non-blocking
// Backend-Sync ueber den Worker, wenn ApiConfig.workerUrl gesetzt ist.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'achievement_service.dart';
import 'streak_tracking_service.dart';
import 'unified_profile_service.dart';

enum ActivityKind {
  toolOpen,
  chatMessage,
  profileEdit,
  articleRead,
  checkIn,
  achievementUnlock,
  questionAnswered,
  pdfShared,
  loginDaily,
  custom,
}

class ActivityEvent {
  final ActivityKind kind;
  final String world; // 'materie' | 'energie' | 'vorhang' | 'ursprung' | 'meta'
  final String label;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ActivityEvent({
    required this.kind,
    required this.world,
    required this.label,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'world': world,
        'label': label,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ActivityLogService {
  ActivityLogService._();
  static final ActivityLogService instance = ActivityLogService._();

  final _controller = StreamController<ActivityEvent>.broadcast();

  /// Live-Stream fuer UI: Confetti, Badge-Updates, in-app Toasts.
  Stream<ActivityEvent> get stream => _controller.stream;

  // ── High-Level Logging-API ────────────────────────────────────────────

  /// Tool-Oeffnung trackt: +5 XP, Achievement-Fortschritt, Event.
  Future<void> logToolOpen({
    required String toolId,
    required String world,
  }) async {
    final evt = ActivityEvent(
      kind: ActivityKind.toolOpen,
      world: world,
      label: 'tool_open:$toolId',
      metadata: {'tool_id': toolId},
    );
    await _dispatch(evt, xp: 5, achievementsToBump: const []);
    // Bestehendes Tool-Tracking weiter triggern (Streak-Punkte).
    await StreakTrackingService().trackToolUsage(toolId);
  }

  /// Chat-Nachricht gesendet -- +3 XP, Streak-Pflege, first-chat-Achievement.
  Future<void> logChatMessage({
    required String world,
    required String roomId,
    int messageLength = 0,
  }) async {
    final evt = ActivityEvent(
      kind: ActivityKind.chatMessage,
      world: world,
      label: 'chat:$world/$roomId',
      metadata: {'room_id': roomId, 'len': messageLength},
    );
    await _dispatch(evt,
        xp: 3, achievementsToBump: const ['first_post', 'commenter']);
  }

  /// Profil-Edit -- +10 XP, Achievement.
  Future<void> logProfileEdit({String world = 'meta'}) async {
    final evt = ActivityEvent(
      kind: ActivityKind.profileEdit,
      world: world,
      label: 'profile_edit',
    );
    await _dispatch(evt,
        xp: 10, achievementsToBump: const ['profile_complete']);
  }

  /// Artikel gelesen -- +3 XP.
  Future<void> logArticleRead({
    required String articleId,
    required String world,
  }) async {
    final evt = ActivityEvent(
      kind: ActivityKind.articleRead,
      world: world,
      label: 'article:$articleId',
      metadata: {'article_id': articleId},
    );
    await _dispatch(evt, xp: 3, achievementsToBump: const ['reader']);
    await StreakTrackingService().trackArticleRead(articleId);
  }

  /// Quiz-Frage richtig beantwortet.
  Future<void> logQuestionAnswered({
    required String quizId,
    required int xp,
    required bool correct,
    String world = 'energie',
  }) async {
    if (!correct) {
      // Falsche Antworten taggen wir trotzdem als Lerneinheit, aber ohne XP.
      _controller.add(ActivityEvent(
        kind: ActivityKind.questionAnswered,
        world: world,
        label: 'quiz:$quizId:wrong',
        metadata: {'quiz_id': quizId, 'correct': false},
      ));
      return;
    }
    final evt = ActivityEvent(
      kind: ActivityKind.questionAnswered,
      world: world,
      label: 'quiz:$quizId',
      metadata: {'quiz_id': quizId, 'correct': true, 'xp': xp},
    );
    await _dispatch(evt, xp: xp, achievementsToBump: const []);
  }

  /// PDF geteilt.
  Future<void> logPdfShared(
      {required String type, String world = 'energie'}) async {
    final evt = ActivityEvent(
      kind: ActivityKind.pdfShared,
      world: world,
      label: 'pdf:$type',
      metadata: {'type': type},
    );
    await _dispatch(evt,
        xp: 10, achievementsToBump: const ['numerology_pdf_share_5']);
  }

  /// Beliebiges Custom-Event (z.B. Feature-Probe).
  Future<void> logCustom({
    required String label,
    required String world,
    int xp = 0,
    Map<String, dynamic> metadata = const {},
    List<String> achievementsToBump = const [],
  }) async {
    final evt = ActivityEvent(
      kind: ActivityKind.custom,
      world: world,
      label: label,
      metadata: metadata,
    );
    await _dispatch(evt, xp: xp, achievementsToBump: achievementsToBump);
  }

  // ── Interne Verteilung ────────────────────────────────────────────────

  Future<void> _dispatch(
    ActivityEvent evt, {
    required int xp,
    required List<String> achievementsToBump,
  }) async {
    // 1) Stream emittieren -- UI reagiert sofort.
    _controller.add(evt);

    // 2) Achievements lokal inkrementieren (fire-and-forget).
    for (final id in achievementsToBump) {
      try {
        await AchievementService().incrementProgress(id);
      } catch (_) {/* ignore */}
    }

    // 3) Backend-Sync fire-and-forget. Worker schreibt in
    //    user_activity_log + addiert XP serverseitig. Quota-schonend,
    //    weil wir nur bei tatsaechlichen Aktionen senden.
    unawaited(_syncToBackend(evt, xp: xp));
  }

  Future<void> _syncToBackend(ActivityEvent evt, {required int xp}) async {
    final userId = UnifiedProfileService.instance.userId;
    final username = UnifiedProfileService.instance.username;
    if ((userId == null || userId.isEmpty) &&
        (username == null || username.isEmpty)) {
      return; // ohne Identitaet kein Sync
    }
    try {
      final url = Uri.parse('${ApiConfig.workerUrl}/api/activity/log');
      await http
          .post(url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': userId,
                'username': username,
                'kind': evt.kind.name,
                'world': evt.world,
                'label': evt.label,
                'metadata': evt.metadata,
                'xp': xp,
                'ts': evt.timestamp.toIso8601String(),
              }))
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Activity-Sync failed: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
