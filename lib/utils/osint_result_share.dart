import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  // ── M-X4: PDF-Export ───────────────────────────────────────────────────────

  /// Rendert das Ergebnis als PDF-Bytes (web-sicher, ohne dart:io).
  static Future<Uint8List> _pdfBytes({
    required String toolName,
    required String query,
    required Map<String, dynamic> result,
  }) async {
    final doc = pw.Document();
    final lines = toMarkdown(toolName: toolName, query: query, result: result)
        .split('\n');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          for (final raw in lines) {
            final line = raw.trimRight();
            if (line.isEmpty) {
              widgets.add(pw.SizedBox(height: 6));
            } else if (line.startsWith('# ')) {
              widgets.add(pw.Header(level: 0, text: line.substring(2)));
            } else if (line.startsWith('## ')) {
              widgets.add(pw.Header(level: 1, text: line.substring(3)));
            } else if (line.startsWith('- ')) {
              widgets.add(pw.Bullet(text: line.substring(2)));
            } else if (line == '---') {
              widgets.add(pw.Divider());
            } else {
              widgets.add(pw.Paragraph(
                text: line.replaceAll('**', ''),
                margin: const pw.EdgeInsets.only(bottom: 2),
              ));
            }
          }
          return widgets;
        },
      ),
    );
    return doc.save();
  }

  /// Exportiert das Ergebnis als PDF und oeffnet den Share-Sheet.
  static Future<void> exportPdf(
    BuildContext context, {
    required String toolName,
    required String query,
    required Map<String, dynamic> result,
  }) async {
    final bytes =
        await _pdfBytes(toolName: toolName, query: query, result: result);
    final base = query.isEmpty ? toolName : '${toolName}_$query';
    final name = '${base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
      subject: '$toolName: $query',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  /// Fertiges AppBar-Action-Menue: Teilen / Kopieren / PDF.
  /// Nur anzeigen, wenn ein Ergebnis vorliegt.
  static Widget actionButton(
    BuildContext context, {
    required String toolName,
    required String query,
    required Map<String, dynamic>? result,
    Color color = Colors.white,
  }) {
    if (result == null || result.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: Icon(Icons.ios_share, color: color, size: 20),
      tooltip: 'Ergebnis exportieren',
      onSelected: (value) {
        switch (value) {
          case 'share':
            share(context, toolName: toolName, query: query, result: result);
            break;
          case 'copy':
            copy(context, toolName: toolName, query: query, result: result);
            break;
          case 'pdf':
            exportPdf(context,
                toolName: toolName, query: query, result: result);
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.ios_share, size: 18),
            title: Text('Teilen'),
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.copy_rounded, size: 18),
            title: Text('Kopieren'),
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.picture_as_pdf_rounded, size: 18),
            title: Text('Als PDF exportieren'),
          ),
        ),
      ],
    );
  }
}
