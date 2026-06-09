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

  const GodModeSuggestion({
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.reason,
  });

  factory GodModeSuggestion.fromJson(Map<String, dynamic> j) =>
      GodModeSuggestion(
        type: (j['type'] as String?) ?? 'verbesserung',
        category: (j['category'] as String?) ?? 'other',
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        reason: (j['reason'] as String?) ?? '',
      );

  String get categoryLabel => GodModeCategory.labelFor(category);
  GodModeType get typeInfo => GodModeType.forSlug(type);
}

/// Ergebnis von suggest(): Vorschlaege + selbstgelernte Bereiche.
class GodModeSuggestResult {
  final List<GodModeSuggestion> suggestions;
  final List<String> learnedTopics;
  const GodModeSuggestResult(this.suggestions, this.learnedTopics);

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
  GodModeType? get typeInfo => wbType == null ? null : GodModeType.forSlug(wbType);
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

/// Client-Service fuer `/api/admin/godmode/*` (nur root_admin).
class GodModeService {
  static const _role = 'root_admin';

  /// KI-Vorschlaege generieren. [area] = optionaler Fokusbereich.
  /// Liefert Vorschlaege (mit Typ + Warum) + selbstgelernte Bereiche.
  static Future<GodModeSuggestResult> suggest({String? area}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/suggest',
        role: _role,
        body: {if (area != null && area.isNotEmpty) 'area': area},
        timeout: const Duration(seconds: 35),
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
      return GodModeSuggestResult(suggestions, learned);
    } on AdminApiException catch (e) {
      if (kDebugMode) debugPrint('godmode.suggest: ${e.statusCode} ${e.bodySnippet}');
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
      if (kDebugMode) debugPrint('godmode.chat: ${e.statusCode} ${e.bodySnippet}');
      return const GodModeChatReply(
        success: false, message: 'Assistent nicht erreichbar -- spaeter erneut.');
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.chat: $e');
      return const GodModeChatReply(success: false, message: 'Netzwerkfehler.');
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
      if (kDebugMode) debugPrint('godmode.submit: ${e.statusCode} ${e.bodySnippet}');
      final msg = e.bodySnippet.contains('godmode_pat_missing')
          ? 'GitHub-PAT fehlt im Worker -- bitte GH_PAT setzen + Worker deployen.'
          : 'Auftrag fehlgeschlagen (${e.statusCode}).';
      return GodModeSubmitResult(success: false, message: msg);
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.submit: $e');
      return const GodModeSubmitResult(success: false, message: 'Netzwerkfehler.');
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
      if (kDebugMode) debugPrint('godmode.list: ${e.statusCode} ${e.bodySnippet}');
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
  static Future<bool> setTopicStatus(String slug, {required bool archived}) async {
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
}
