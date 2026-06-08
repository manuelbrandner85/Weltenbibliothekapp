import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'admin_api_client.dart';

// Plain classes statt Dart-3-Named-Records (wuerden dart2js crashen, CLAUDE.md).

/// Die sechs God-Mode-Kategorien.
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

/// KI-Verbesserungsvorschlag.
class GodModeSuggestion {
  final String category;
  final String title;
  final String description;

  const GodModeSuggestion({
    required this.category,
    required this.title,
    required this.description,
  });

  factory GodModeSuggestion.fromJson(Map<String, dynamic> j) =>
      GodModeSuggestion(
        category: (j['category'] as String?) ?? 'other',
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
      );

  String get categoryLabel => GodModeCategory.labelFor(category);
}

/// Abgesetzter Auftrag mit Status + Links.
class GodModeRequest {
  final String id;
  final String category;
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
  bool get isAi => source == 'ai_suggestion';
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
  static Future<List<GodModeSuggestion>> suggest({String? area}) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/suggest',
        role: _role,
        body: {if (area != null && area.isNotEmpty) 'area': area},
        timeout: const Duration(seconds: 30),
      );
      final list = data['suggestions'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(GodModeSuggestion.fromJson)
            .toList();
      }
      return const [];
    } on AdminApiException catch (e) {
      if (kDebugMode) debugPrint('godmode.suggest: ${e.statusCode} ${e.bodySnippet}');
      return const [];
    } catch (e) {
      if (kDebugMode) debugPrint('godmode.suggest: $e');
      return const [];
    }
  }

  /// Auftrag absetzen -> GitHub-Issue -> Claude baut autonom.
  static Future<GodModeSubmitResult> submit({
    required String category,
    required String title,
    required String description,
    bool fromAi = false,
  }) async {
    try {
      final data = await AdminApiClient.instance.postJson(
        '/api/admin/godmode/request',
        role: _role,
        body: {
          'category': category,
          'title': title,
          'description': description,
          'source': fromAi ? 'ai_suggestion' : 'manual',
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
          ? 'GODMODE_GH_PAT Secret fehlt im Worker -- bitte Secret setzen + Worker deployen.'
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
}
