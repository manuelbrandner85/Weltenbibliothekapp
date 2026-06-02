import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'wb_toast.dart';

/// M2: Export-Helfer fuer OSINT-Einzeltool-Ergebnisse.
///
/// Formatiert eine Result-Map als lesbaren Markdown-Text und bietet
/// Teilen (nativer Share-Sheet) bzw. Kopieren in die Zwischenablage.
class OsintResultShare {
  /// Wandelt [result] in einen lesbaren Markdown-Block.
  static String toMarkdown({
    required String toolName,
    required String query,
    required Map<String, dynamic> result,
  }) {
    final buf = StringBuffer();
    buf.writeln('# $toolName');
    buf.writeln('');
    if (query.isNotEmpty) {
      buf.writeln('**Abfrage:** $query');
      buf.writeln('');
    }
    _writeMap(buf, result, 0);
    buf.writeln('');
    buf.writeln('---');
    buf.writeln('_Erstellt mit der Weltenbibliothek-App. Oeffentlich '
        'zugaengliche Daten - bitte kritisch pruefen._');
    return buf.toString();
  }

  static void _writeMap(StringBuffer buf, Map<String, dynamic> map, int depth) {
    final indent = '  ' * depth;
    map.forEach((key, value) {
      if (value == null) return;
      final label = _humanize(key);
      if (value is Map<String, dynamic>) {
        buf.writeln('$indent## $label');
        _writeMap(buf, value, depth);
      } else if (value is Map) {
        buf.writeln('$indent## $label');
        _writeMap(buf, Map<String, dynamic>.from(value), depth);
      } else if (value is List) {
        if (value.isEmpty) return;
        buf.writeln('$indent**$label:**');
        for (final item in value) {
          buf.writeln('$indent- $item');
        }
      } else {
        buf.writeln('$indent**$label:** $value');
      }
    });
  }

  static String _humanize(String key) {
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
  }

  /// Oeffnet den nativen Share-Sheet mit dem formatierten Ergebnis.
  static Future<void> share(
    BuildContext context, {
    required String toolName,
    required String query,
    required Map<String, dynamic> result,
  }) async {
    final md = toMarkdown(toolName: toolName, query: query, result: result);
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      md,
      subject: '$toolName: $query',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  /// Kopiert das formatierte Ergebnis in die Zwischenablage (+ Toast).
  static Future<void> copy(
    BuildContext context, {
    required String toolName,
    required String query,
    required Map<String, dynamic> result,
  }) async {
    final md = toMarkdown(toolName: toolName, query: query, result: result);
    await Clipboard.setData(ClipboardData(text: md));
    if (context.mounted) {
      WBToast.success(context, '📋 Ergebnis kopiert');
    }
  }

  /// Fertiges AppBar-Action-Icon, das den Share-Sheet oeffnet.
  /// Nur anzeigen, wenn ein Ergebnis vorliegt.
  static Widget actionButton(
    BuildContext context, {
    required String toolName,
    required String query,
    required Map<String, dynamic>? result,
    Color color = Colors.white,
  }) {
    if (result == null || result.isEmpty) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(Icons.ios_share, color: color, size: 20),
      tooltip: 'Ergebnis teilen',
      onPressed: () => share(
        context,
        toolName: toolName,
        query: query,
        result: result,
      ),
    );
  }
}
