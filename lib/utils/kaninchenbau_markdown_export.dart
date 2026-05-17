// Kaninchenbau-Markdown-Export (C1).
//
// Wandelt einen Investigation-State in einen vollständigen Markdown-
// Dump. Anders als _shareThread (nur Summary in Clipboard) enthält
// dieser Export ALLE Karten (Identity / Netzwerk / Personen / RSS /
// Skandale / AI-Insights / Documents / etc).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wb_toast.dart';

class KaninchenbauMarkdownExport {
  static String toMarkdown({
    required String topic,
    required Map<String, dynamic>? identity,
    required List<Map<String, dynamic>> networkNodes,
    required List<Map<String, dynamic>> keyPersons,
    required List<Map<String, dynamic>> rssItems,
    required List<Map<String, dynamic>> skandale,
    required String? aiInsight,
    required List<Map<String, dynamic>> documents,
    required List<Map<String, dynamic>> sanctions,
    required List<Map<String, dynamic>> moneyFlow,
    DateTime? generatedAt,
  }) {
    final buf = StringBuffer();
    final now = generatedAt ?? DateTime.now();

    buf.writeln('# 🐇 Kaninchenbau: $topic');
    buf.writeln('');
    buf.writeln(
        '_Generiert am ${now.toIso8601String()} via Weltenbibliothek-App_');
    buf.writeln('');

    if (identity != null) {
      buf.writeln('## Identität');
      buf.writeln('');
      buf.writeln('**${identity['label'] ?? topic}**');
      final desc = identity['description'];
      if (desc is String && desc.isNotEmpty) {
        buf.writeln('');
        buf.writeln(desc);
      }
      buf.writeln('');
    }

    if (networkNodes.isNotEmpty) {
      buf.writeln('## Netzwerk (${networkNodes.length})');
      buf.writeln('');
      for (final n in networkNodes.take(40)) {
        final label = n['label'] ?? n['id'] ?? '?';
        final type = n['type'] ?? '';
        buf.writeln('- **$label**${type.isNotEmpty ? "  _($type)_" : ""}');
      }
      buf.writeln('');
    }

    if (keyPersons.isNotEmpty) {
      buf.writeln('## Schlüsselpersonen (${keyPersons.length})');
      buf.writeln('');
      for (final p in keyPersons.take(30)) {
        final name = p['name'] ?? '?';
        final role = p['role'] ?? p['title'] ?? '';
        buf.writeln('- **$name**${role.isNotEmpty ? " — $role" : ""}');
      }
      buf.writeln('');
    }

    if (documents.isNotEmpty) {
      buf.writeln('## Dokumente (${documents.length})');
      buf.writeln('');
      for (final d in documents.take(20)) {
        final title = d['title'] ?? d['name'] ?? '?';
        final url = d['url'] ?? d['link'] ?? '';
        if (url.toString().isNotEmpty) {
          buf.writeln('- [$title]($url)');
        } else {
          buf.writeln('- $title');
        }
      }
      buf.writeln('');
    }

    if (sanctions.isNotEmpty) {
      buf.writeln('## Sanktionen / OpenSanctions (${sanctions.length})');
      buf.writeln('');
      for (final s in sanctions.take(15)) {
        buf.writeln('- ${s['name'] ?? '?'} — ${s['program'] ?? s['description'] ?? ''}');
      }
      buf.writeln('');
    }

    if (moneyFlow.isNotEmpty) {
      buf.writeln('## Geldfluss (${moneyFlow.length})');
      buf.writeln('');
      for (final m in moneyFlow.take(15)) {
        buf.writeln('- ${m['from'] ?? '?'} → ${m['to'] ?? '?'} '
            '(${m['amount'] ?? '?'})');
      }
      buf.writeln('');
    }

    if (rssItems.isNotEmpty) {
      buf.writeln('## Aktuelle Berichte (${rssItems.length})');
      buf.writeln('');
      for (final item in rssItems.take(20)) {
        final title = item['title'] ?? '?';
        final url = item['url'] ?? item['link'] ?? '';
        final source = item['source'] ?? '';
        if (url.toString().isNotEmpty) {
          buf.writeln('- [$title]($url)${source.isNotEmpty ? " _($source)_" : ""}');
        } else {
          buf.writeln('- $title');
        }
      }
      buf.writeln('');
    }

    if (skandale.isNotEmpty) {
      buf.writeln('## Kontroversen / Skandale (${skandale.length})');
      buf.writeln('');
      for (final s in skandale.take(15)) {
        buf.writeln('- **${s['title'] ?? '?'}**');
        final body = s['description'] ?? s['summary'] ?? '';
        if (body.toString().isNotEmpty) {
          buf.writeln('  ${body.toString().substring(0, body.toString().length.clamp(0, 300))}');
        }
      }
      buf.writeln('');
    }

    if (aiInsight != null && aiInsight.isNotEmpty) {
      buf.writeln('## Virgil-Analyse');
      buf.writeln('');
      buf.writeln('> $aiInsight');
      buf.writeln('');
    }

    buf.writeln('---');
    buf.writeln('_Quellen sind in den jeweiligen Links referenziert. Bitte ');
    buf.writeln('kritisch prüfen — die App aggregiert öffentlich zugängliche ');
    buf.writeln('Daten, ersetzt aber keine eigene Recherche._');

    return buf.toString();
  }

  /// Kopiert Markdown in Zwischenablage + Toast-Feedback.
  static Future<void> copyToClipboard(
    BuildContext context,
    String markdown,
  ) async {
    await Clipboard.setData(ClipboardData(text: markdown));
    if (context.mounted) {
      WBToast.success(context, '📋 Markdown in Zwischenablage');
    }
  }
}

