// BranchBossTestService — 15-Fragen-Boss-Test pro Vorhang-Branch (I3).

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class BossQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  const BossQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory BossQuestion.fromJson(Map<String, dynamic> j) => BossQuestion(
        question: j['q'] as String? ?? '',
        options: (j['options'] as List?)?.cast<String>() ?? const [],
        correctIndex: (j['correct'] as int?) ?? 0,
        explanation: j['explanation'] as String?,
      );
}

class BossTest {
  final String id;
  final String branch;
  final String title;
  final String? description;
  final List<BossQuestion> questions;
  final int passPct;
  final int xpReward;
  const BossTest({
    required this.id,
    required this.branch,
    required this.title,
    required this.description,
    required this.questions,
    required this.passPct,
    required this.xpReward,
  });

  factory BossTest.fromJson(Map<String, dynamic> j) {
    final raw = (j['questions'] as List?) ?? [];
    return BossTest(
      id: j['id'] as String,
      branch: j['branch'] as String? ?? '',
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      questions: raw
          .whereType<Map>()
          .map((q) => BossQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
      passPct: (j['pass_pct'] as int?) ?? 80,
      xpReward: (j['xp_reward'] as int?) ?? 300,
    );
  }
}

class BossAttemptResult {
  final bool passed;
  final int scorePct;
  final int correctCount;
  final int totalCount;
  const BossAttemptResult({
    required this.passed,
    required this.scorePct,
    required this.correctCount,
    required this.totalCount,
  });
}

class BranchBossTestService {
  BranchBossTestService._();
  static final instance = BranchBossTestService._();

  SupabaseClient get _s => Supabase.instance.client;

  Future<BossTest?> forBranch(String branch) async {
    try {
      final res = await _s
          .from('vorhang_branch_boss_tests')
          .select()
          .eq('branch', branch)
          .maybeSingle();
      if (res == null) return null;
      return BossTest.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ BossTest: $e');
      return null;
    }
  }

  /// Berechnet das Resultat aus Antwort-Indizes. Schreibt Attempt + ggf.
  /// XP-Bonus separat (Caller muss XP-Service triggern wenn passed).
  BossAttemptResult evaluate(BossTest test, List<int> answers) {
    if (test.questions.isEmpty || answers.length != test.questions.length) {
      return const BossAttemptResult(
          passed: false, scorePct: 0, correctCount: 0, totalCount: 0);
    }
    int correct = 0;
    for (var i = 0; i < test.questions.length; i++) {
      if (answers[i] == test.questions[i].correctIndex) correct++;
    }
    final pct = ((correct / test.questions.length) * 100).round();
    return BossAttemptResult(
      passed: pct >= test.passPct,
      scorePct: pct,
      correctCount: correct,
      totalCount: test.questions.length,
    );
  }

  Future<bool> recordAttempt({
    required String userId,
    required String branch,
    required BossAttemptResult result,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _s.from('vorhang_branch_boss_attempts').insert({
        'user_id': userId,
        'branch': branch,
        'score_pct': result.scorePct,
        'passed': result.passed,
        'details': details ?? {},
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ BossAttempt record: $e');
      return false;
    }
  }
}
