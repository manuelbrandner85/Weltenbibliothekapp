// KnowledgeConnectService — AI-Vorschläge für Knowledge-Graph (L4).

import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ConnectSuggestion {
  final String from;
  final String to;
  final String reason;
  const ConnectSuggestion({
    required this.from,
    required this.to,
    required this.reason,
  });
}

// dart2js-Bug-Workaround: Named Records kompilieren nicht zuverlaessig.
class KnowledgeNode {
  final String id;
  final String label;
  final String? description;
  const KnowledgeNode({
    required this.id,
    required this.label,
    this.description,
  });
}

class KnowledgeConnectService {
  KnowledgeConnectService._();
  static final instance = KnowledgeConnectService._();

  Future<List<ConnectSuggestion>> suggest(
    List<KnowledgeNode> nodes,
  ) async {
    if (nodes.length < 2) return const [];
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/knowledge/connect-suggest'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nodes': nodes
                  .map((n) => {
                        'id': n.id,
                        'label': n.label,
                        if (n.description != null) 'description': n.description,
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['suggestions'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((m) => ConnectSuggestion(
                from: m['from'] as String? ?? '',
                to: m['to'] as String? ?? '',
                reason: m['reason'] as String? ?? '',
              ))
          .where((s) => s.from.isNotEmpty && s.to.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Connect suggest: $e');
      return const [];
    }
  }
}
