import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'admin_api_client.dart';

// Plain classes statt Dart-3-Named-Records (wuerden dart2js crashen, CLAUDE.md).

/// Die sechs God-Mode-Kategorien (Bereich).
class GodModeCategory {
  final String slug;
  final String label;
  const GodModeCategory(this.slug, this.label);

  static const List<GodModeCategory> all = [
    GodModeCategory('ui_ux', 'UI/UX & Design'),
    GodModeCategory('feature', 'Feature'),
    GodModeCategory('module', 'Modul & Inhalt'),
    GodModeCategory('bugfix', 'Bugfix'),
    GodModeCategory('performance', 'Performance'),
    GodModeCategory('other', 'Sonstiges'),
  ];

  static String labelFor(String slug) {
    for (final c in all) {
      if (c.slug == slug) return c.label;
    }
    return 'Sonstiges';
  }
}

/// Massnahmen-Typ: WAS fuer eine Aenderung (Bug, Neuerung, Erweiterung, ...).
/// Jeder Typ hat ein Emoji-Badge + eine Farbe (ARGB-Int, ohne Material-Import).
class GodModeType {
  final String slug;
  final String label;
  final String emoji;
  final int colorValue; // 0xAARRGGBB
  const GodModeType(this.slug, this.label, this.emoji, this.colorValue);

  static const List<GodModeType> all = [
    GodModeType('bug', 'Fehler/Bug', '🐞', 0xFFFF5252),
    GodModeType('neuerung', 'Neuerung', '✨', 0xFF7C4DFF),
    GodModeType('erweiterung', 'Erweiterung', '🧩', 0xFF26C6DA),
    GodModeType('verbesserung', 'Verbesserung', '⬆️', 0xFF66BB6A),
    GodModeType('performance', 'Performance', '⚡', 0xFFFFCA28),
    GodModeType('ux', 'UX/Design', '🎨', 0xFFFF8A65),
  ];

  static GodModeType forSlug(String? slug) {
    for (final t in all) {
      if (t.slug == slug) return t;
    }
    return all[3]; // verbesserung als Default
  }
}

/// KI-Vorschlag inkl. Typ + Begruendung (Warum).
class GodModeSuggestion {
  final String type;
  final String category;
  final String title;
  final String description;
  final String reason;

  /// Nutzen (1..5) und Aufwand (1..5) -- fuer Impact-Sortierung (N2).
  final int impact;
  final int effort;

  const GodModeSuggestion({
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.reason,
    this.impact = 3,
    this.effort = 3,
  });

  factory GodModeSuggestion.fromJson(Map<String, dynamic> j) =>
      GodModeSuggestion(
        type: (j['type'] as String?) ?? 'verbesserung',
        category: (j['category'] as String?) ?? 'other',
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        reason: (j['reason'] as String?) ?? '',
        impact: _clamp15(j['impact']),
        effort: _clamp15(j['effort']),
      );

  static int _clamp15(dynamic v) {
    final n = v is int ? v : int.tryParse('${v ?? ''}');
    if (n == null) return 3;
    return n < 1 ? 1 : (n > 5 ? 5 : n);
  }

  /// Quick-Win-Score: hoher Nutzen, niedriger Aufwand zuerst.
  int get score => impact * 2 - effort;

  String get categoryLabel => GodModeCategory.labelFor(category);
  GodModeType get typeInfo => GodModeType.forSlug(type);
}

/// Ergebnis von suggest(): Vorschlaege + selbstgelernte Bereiche.
class GodModeSuggestResult {
  final List<GodModeSuggestion> suggestions;
  final List<String> learnedTopics;

  /// KI-Quelle: groq | openrouter | gemini | workers-ai | fallback.
  final String source;

  const GodModeSuggestResult(
    this.suggestions,
    this.learnedTopics, {
    this.source = '',
  });

  /// true, wenn echte KI geantwortet hat (kein Standard-Fallback).
  bool get isAi => source.isNotEmpty && source != 'fallback';

  static const GodModeSuggestResult empty =
      GodModeSuggestResult(<GodModeSuggestion>[], <String>[]);
}

/// Selbstgelernter / manueller Themen-Bereich.
class GodModeTopic {
  final String slug;
  final String label;
  final String origin; // 'ai' | 'manual'
  final int hitCount;

  const GodModeTopic({
    required this.slug,
    required this.label,
    required this.origin,
    required this.hitCount,
  });

  factory GodModeTopic.fromJson(Map<String, dynamic> j) => GodModeTopic(
        slug: (j['slug'] as String?) ?? '',
        label: (j['label'] as String?) ?? '',
        origin: (j['origin'] as String?) ?? 'ai',
        hitCount: (j['hit_count'] as int?) ?? 1,
      );

  bool get isAi => origin == 'ai';
}

/// Eine Chat-Nachricht (Dialog mit dem God-Mode-Assistenten).
class GodModeChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  const GodModeChatMessage(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
  bool get isUser => role == 'user';
}

/// Antwort des Chat-Assistenten. [readyToSubmit] != null => Auftrag fertig,
/// Admin muss nur noch bestaetigen.
class GodModeChatReply {
  final bool success;
  final String message;
  final GodModeReadyOrder? readyToSubmit;
  const GodModeChatReply({
    required this.success,
    required this.message,
    this.readyToSubmit,
  });
}

/// Fertig formulierter Auftrag aus dem Chat (wartet auf Ja/Nein des Admins).
class GodModeReadyOrder {
  final String category;
  final String type;
  final String title;
  final String description;
  const GodModeReadyOrder({
    required this.category,
    required this.type,
    required this.title,
    required this.description,
  });

  factory GodModeReadyOrder.fromJson(Map<String, dynamic> j) =>
      GodModeReadyOrder(
        category: (j['category'] as String?) ?? 'other',
        type: (j['type'] as String?) ?? 'verbesserung',
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
      );
}

/// Abgesetzter Auftrag mit Status + Links.
class GodModeRequest {
  final String id;
  final String category;
  final String? wbType;
  final String title;
  final String description;
  final String source;
  final String status;
  final int? issueNumber;
  final String? issueUrl;
  final int? prNumber;
  final String? prUrl;
  final String? error;
  final String? createdAt;

  const GodModeRequest({
    required this.id,
    required this.category,
    this.wbType,
    required this.title,
    required this.description,
    required this.source,
    required this.status,
    this.issueNumber,
    this.issueUrl,
    this.prNumber,
    this.prUrl,
    this.error,
    this.createdAt,
  });

  factory GodModeRequest.fromJson(Map<String, dynamic> j) => GodModeRequest(
        id: (j['id'] as String?) ?? '',
        category: (j['category'] as String?) ?? 'other',
        wbType: j['wb_type'] as String?,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        source: (j['source'] as String?) ?? 'manual',
        status: (j['status'] as String?) ?? 'queued',
        issueNumber: j['issue_number'] as int?,
        issueUrl: j['issue_url'] as String?,
        prNumber: j['pr_number'] as int?,
        prUrl: j['pr_url'] as String?,
        error: j['error'] as String?,
        createdAt: j['created_at'] as String?,
      );

  String get categoryLabel => GodModeCategory.labelFor(category);
  GodModeType? get typeInfo =>
      wbType == null ? null : GodModeType.forSlug(wbType);
  bool get isAi => source == 'ai_suggestion';
  bool get isChat => source == 'chat';
}

/// Ergebnis eines Auftrag-Submits.
class GodModeSubmitResult {
  final bool success;
  final String message;
  final int? issueNumber;
  final String? issueUrl;

  const GodModeSubmitResult({
    required this.success,
    required this.message,
    this.issueNumber,
    this.issueUrl,
  });
}

/// Ein Eintrag im Repo-Tab (PR / CI-Run / Issue / Commit).
class GodModeRepoEntry {
  final String title;
  final String url;
  final String meta;
  const GodModeRepoEntry({
    required this.title,
    required this.url,
    required this.meta,
  });
}

/// Live-Repo-Insights fuer den Repo-Tab (A1).
class GodModeRepoInsights {
  final List<GodModeRepoEntry> pulls;
  final List<GodModeRepoEntry> runs;
  final List<GodModeRepoEntry> issues;
  final List<GodModeRepoEntry> commits;

  /// C5: konfigurierte KI-Provider (name -> aktiv) + Auftrag-Statistik.
  final Map<String, bool> providers;
  final Map<String, int> stats;

  /// D: Pipeline-Cockpit -- Builder-Modell, letztes Release, App-Versionen.
  final String model;
  final String releaseTag;
  final String releaseName;
  final String latestVersion;
  final String minVersion;

  const GodModeRepoInsights({
    required this.pulls,
    required this.runs,
    required this.issues,
    required this.commits,
    this.providers = const {},
    this.stats = const {},
    this.model = '',
    this.releaseTag = '',
    this.releaseName = '',
    this.latestVersion = '',
    this.minVersion = '',
  });
  static const empty = GodModeRepoInsights(
    pulls: [],
    runs: [],
    issues: [],
    commits: [],
  );
}

/// Client-Service fuer `/api/admin/godmode/*` (nur root_admin).
class GodModeService {
  static const _role = 'root_admin';

  /// KI-Vorschlaege generieren. [area] = optionaler Fokusbereich,
  /// [world] = optionaler Welt-Fokus (materie|energie|vorhang|ursprung).
  /// Liefert Vorschlaege (mit Typ + Warum) + selbstgelernte Bereiche.
  static Future<GodModeSuggestResult> suggest(
      {String? area, String? world, bool vote = false}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/suggest',
        role: _role,
        body: {
          if (area != null && area.isNotEmpty) 'area': area,
          if (world != null && world.isNotEmpty) 'world': world,
          if (vote) 'vote': true,
        },
        timeout: const Duration(seconds: 50),
      );
      final list = data['suggestions'];
      final topics = data['learnedTopics'];
      final suggestions = (list is List)
          ? list
              .whereType<Map<String, dynamic>>()
              .map(GodModeSuggestion.fromJson)
              .toList()
          : <GodModeSuggestion>[];
      final learned = (topics is List)
          ? topics.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
          : <String>[];
      final source = (data['source'] as String?) ?? '';
      return GodModeSuggestResult(suggestions, learned, source: source);
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('godmode.suggest: ${e.statusCode} ${e.bodySnippet}');
      }
      return GodModeSuggestResult.empty;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.suggest: $e');
      return GodModeSuggestResult.empty;
    }
  }

  /// Chat-Dialog: der Assistent stellt Rueckfragen und formuliert den Auftrag.
  /// [history] = bisheriger Verlauf inkl. der neuen User-Nachricht.
  static Future<GodModeChatReply> chat(List<GodModeChatMessage> history) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/chat',
        role: _role,
        body: {'messages': history.map((m) => m.toJson()).toList()},
        timeout: const Duration(seconds: 35),
      );
      final ready = data['readyToSubmit'];
      return GodModeChatReply(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? '',
        readyToSubmit: (ready is Map<String, dynamic>)
            ? GodModeReadyOrder.fromJson(ready)
            : null,
      );
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('godmode.chat: ${e.statusCode} ${e.bodySnippet}');
      }
      return const GodModeChatReply(
          success: false,
          message: 'Assistent nicht erreichbar -- spaeter erneut.');
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.chat: $e');
      return const GodModeChatReply(success: false, message: 'Netzwerkfehler.');
    }
  }

  /// Batch3: KI-priorisierte Roadmap aus den offenen Auftraegen (Markdown).
  static Future<String> roadmap() async {
    try {
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/godmode/roadmap',
        role: _role,
      );
      return (data['roadmap'] as String?) ?? '';
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.roadmap: $e');
      return '';
    }
  }

  /// Screenshot-zu-Auftrag (multimodal): Bild (base64) an die KI, die daraus
  /// einen fertigen Auftrag formuliert. Liefert null wenn nichts erkannt wurde.
  static Future<GodModeReadyOrder?> vision({
    required String imageBase64,
    required String mime,
    String? hint,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/vision',
        role: _role,
        body: {
          'image': imageBase64,
          'mime': mime,
          if (hint != null && hint.isNotEmpty) 'hint': hint,
        },
        timeout: const Duration(seconds: 50),
      );
      final order = data['order'];
      if (order is Map<String, dynamic>) {
        return GodModeReadyOrder.fromJson(order);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.vision: $e');
      return null;
    }
  }

  /// Auftrag absetzen -> GitHub-Issue -> Claude baut autonom.
  static Future<GodModeSubmitResult> submit({
    required String category,
    required String title,
    required String description,
    String? type,
    String source = 'manual',
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/request',
        role: _role,
        body: {
          'category': category,
          if (type != null && type.isNotEmpty) 'type': type,
          'title': title,
          'description': description,
          'source': source,
        },
        timeout: const Duration(seconds: 30),
      );
      return GodModeSubmitResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Auftrag angelegt.',
        issueNumber: data['issue_number'] as int?,
        issueUrl: data['issue_url'] as String?,
      );
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('godmode.submit: ${e.statusCode} ${e.bodySnippet}');
      }
      final msg = e.bodySnippet.contains('godmode_pat_missing')
          ? 'GitHub-PAT fehlt im Worker -- bitte GH_PAT setzen + Worker deployen.'
          : 'Auftrag fehlgeschlagen (${e.statusCode}).';
      return GodModeSubmitResult(success: false, message: msg);
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.submit: $e');
      return const GodModeSubmitResult(
          success: false, message: 'Netzwerkfehler.');
    }
  }

  /// Letzte 50 Auftraege mit Status + Links.
  static Future<List<GodModeRequest>> listRequests() async {
    try {
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/godmode/requests',
        role: _role,
      );
      final list = data['requests'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(GodModeRequest.fromJson)
            .toList();
      }
      return const [];
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('godmode.list: ${e.statusCode} ${e.bodySnippet}');
      }
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.list: $e');
      return const [];
    }
  }

  /// Selbstgelernte + manuelle Themen-Bereiche.
  static Future<List<GodModeTopic>> listTopics() async {
    try {
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/godmode/topics',
        role: _role,
      );
      final list = data['topics'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(GodModeTopic.fromJson)
            .toList();
      }
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.topics: $e');
      return const [];
    }
  }

  /// A1: Live-Repo-Insights (PRs, fehlgeschlagene CI, Issues, Commits).
  static Future<GodModeRepoInsights> repoInsights() async {
    try {
      final data = await AdminApiClient.instance.getJson(
        '/api/admin/godmode/repo',
        role: _role,
      );
      List<GodModeRepoEntry> parse(
          String key, GodModeRepoEntry Function(Map<String, dynamic>) f) {
        final l = data[key];
        return (l is List)
            ? l.whereType<Map<String, dynamic>>().map(f).toList()
            : <GodModeRepoEntry>[];
      }

      return GodModeRepoInsights(
        pulls: parse(
            'pulls',
            (j) => GodModeRepoEntry(
                  title: '#${j['number']} ${j['title'] ?? ''}',
                  url: (j['url'] as String?) ?? '',
                  meta: j['draft'] == true ? 'Draft' : 'offen',
                )),
        runs: parse(
            'runs',
            (j) => GodModeRepoEntry(
                  title: (j['name'] as String?) ?? 'CI',
                  url: (j['url'] as String?) ?? '',
                  meta: (j['sha'] as String?) ?? '',
                )),
        issues: parse(
            'issues',
            (j) => GodModeRepoEntry(
                  title: '#${j['number']} ${j['title'] ?? ''}',
                  url: (j['url'] as String?) ?? '',
                  meta: '',
                )),
        commits: parse(
            'commits',
            (j) => GodModeRepoEntry(
                  title: (j['message'] as String?) ?? '',
                  url: (j['url'] as String?) ?? '',
                  meta: '',
                )),
        providers: (data['providers'] is Map)
            ? (data['providers'] as Map)
                .map((k, v) => MapEntry(k.toString(), v == true))
            : const {},
        stats: (data['stats'] is Map)
            ? (data['stats'] as Map)
                .map((k, v) => MapEntry(k.toString(), (v is int) ? v : 0))
            : const {},
        model: (data['model'] as String?) ?? '',
        releaseTag: (data['release'] is Map)
            ? (((data['release'] as Map)['tag'] as String?) ?? '')
            : '',
        releaseName: (data['release'] is Map)
            ? (((data['release'] as Map)['name'] as String?) ?? '')
            : '',
        latestVersion: (data['app_version'] is Map)
            ? (((data['app_version'] as Map)['latest_version'] as String?) ??
                '')
            : '',
        minVersion: (data['app_version'] is Map)
            ? (((data['app_version'] as Map)['min_version'] as String?) ?? '')
            : '',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.repoInsights: $e');
      return GodModeRepoInsights.empty;
    }
  }

  /// G1: kurze Umsetzungs-Plan-Vorschau fuer einen Auftrag (vor dem Bauen).
  static Future<String> plan({
    required String title,
    required String description,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/plan',
        role: _role,
        body: {'title': title, 'description': description},
        timeout: const Duration(seconds: 35),
      );
      return (data['plan'] as String?) ?? '';
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.plan: $e');
      return '';
    }
  }

  /// B1: Bereich umbenennen.
  static Future<bool> renameTopic(String slug, String label) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/topics',
        role: _role,
        body: {'action': 'rename', 'slug': slug, 'label': label},
      );
      return data['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.renameTopic: $e');
      return false;
    }
  }

  /// B1: Bereich [from] in [into] zusammenfuehren (from wird archiviert).
  static Future<bool> mergeTopic({
    required String from,
    required String into,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/topics',
        role: _role,
        body: {'action': 'merge', 'slug': from, 'into': into},
      );
      return data['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.mergeTopic: $e');
      return false;
    }
  }

  /// Bereich manuell anlegen.
  static Future<bool> addTopic(String label) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/topics',
        role: _role,
        body: {'label': label},
      );
      return data['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.addTopic: $e');
      return false;
    }
  }

  /// Bereich archivieren (oder reaktivieren).
  static Future<bool> setTopicStatus(String slug,
      {required bool archived}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/topics',
        role: _role,
        body: {'slug': slug, 'status': archived ? 'archived' : 'active'},
      );
      return data['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.setTopicStatus: $e');
      return false;
    }
  }

  /// Auftrag aus der Datenbank loeschen.
  static Future<bool> deleteRequest(String id) async {
    try {
      await AdminApiClient.instance.deleteJson(
        '/api/admin/godmode/request/$id',
        role: _role,
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.deleteRequest: $e');
      return false;
    }
  }

  /// Fehlgeschlagenen Auftrag erneut als GitHub-Issue absetzen.
  static Future<GodModeSubmitResult> retryRequest(String id) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/request/$id/retry',
        role: _role,
        body: {},
        timeout: const Duration(seconds: 30),
      );
      return GodModeSubmitResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Auftrag erneut angelegt.',
        issueNumber: data['issue_number'] as int?,
        issueUrl: data['issue_url'] as String?,
      );
    } on AdminApiException catch (e) {
      if (kDebugMode) {
        debugPrint('godmode.retryRequest: ${e.statusCode} ${e.bodySnippet}');
      }
      return GodModeSubmitResult(
          success: false, message: 'Fehler (${e.statusCode}).');
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.retryRequest: $e');
      return const GodModeSubmitResult(
          success: false, message: 'Netzwerkfehler.');
    }
  }
}
