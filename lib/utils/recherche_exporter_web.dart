/// WELTENBIBLIOTHEK v5.6 – EXPORT-FUNKTIONALITÄT
/// 
/// Export von Recherche-Ergebnissen in verschiedenen Formaten:
/// - PDF: Professionelle Dokumente mit Formatierung
/// - Markdown: Für Notizen und GitHub/Wikis
/// - JSON: Maschinenlesbare Rohdaten
/// - TXT: Einfacher Fließtext
library;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class RechercheExporter {
  /// Exportiert Recherche-Daten in verschiedenen Formaten
  static void exportResearch({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String query,
    required String format,
  }) {
    try {
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final filename = 'recherche_${query.replaceAll(' ', '_')}_$timestamp';

      switch (format.toLowerCase()) {
        case 'pdf':
          _generatePDF(data, query, filename);
          break;
        case 'md':
        case 'markdown':
          _generateMarkdown(data, query, filename);
          break;
        case 'json':
          _downloadJSON(data, query, filename);
          break;
        case 'txt':
          _generateText(data, query, filename);
          break;
        default:
          throw Exception('Unbekanntes Format: $format');
      }

      // Erfolgs-Nachricht
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Export erfolgreich: $filename.$format'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Fehler-Nachricht
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export fehlgeschlagen: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// PDF-EXPORT (HTML-basiert für Web-Kompatibilität)
  static void _generatePDF(Map<String, dynamic> data, String query, String filename) {
    // HTML-Dokument generieren (wird vom Browser als PDF gedruckt)
    final htmlContent = _buildHTMLDocument(data, query);
    
    if (kIsWeb) {
      // Web: HTML in neuem Fenster öffnen für Browser-Druckfunktion
      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      
      // Hinweis für Benutzer
      debugPrint('💡 PDF-Export: Nutze Browser-Druckfunktion (Strg+P) um PDF zu speichern');
    } else {
      throw Exception('PDF-Export nur für Web verfügbar');
    }
  }

  /// MARKDOWN-EXPORT
  static void _generateMarkdown(Map<String, dynamic> data, String query, String filename) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('# WELTENBIBLIOTHEK RECHERCHE');
    buffer.writeln();
    buffer.writeln('**Thema**: $query');
    buffer.writeln('**Datum**: ${DateTime.now().toLocal()}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Strukturierte Daten extrahieren
    final structured = data['structured'] as Map<String, dynamic>?;
    final inhalt = data['inhalt'] as String? ?? '';
    
    // FAKTEN
    buffer.writeln('## 📌 FAKTEN');
    buffer.writeln();
    if (structured != null && structured.containsKey('faktenbasis')) {
      final fb = structured['faktenbasis'] as Map<String, dynamic>;
      
      if (fb.containsKey('facts') && fb['facts'] is List) {
        buffer.writeln('### Belegbare Fakten');
        for (var fact in fb['facts']) {
          buffer.writeln('- $fact');
        }
        buffer.writeln();
      }
      
      if (fb.containsKey('actors') && fb['actors'] is List) {
        buffer.writeln('### Beteiligte Akteure');
        for (var actor in fb['actors']) {
          buffer.writeln('- $actor');
        }
        buffer.writeln();
      }
      
      if (fb.containsKey('organizations') && fb['organizations'] is List) {
        buffer.writeln('### Organisationen');
        for (var org in fb['organizations']) {
          buffer.writeln('- $org');
        }
        buffer.writeln();
      }
    }
    
    buffer.writeln('---');
    buffer.writeln();
    
    // QUELLEN
    buffer.writeln('## 🔗 QUELLEN');
    buffer.writeln();
    
    if (structured != null) {
      if (structured.containsKey('sichtweise1_offiziell')) {
        final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
        if (view1 != null && view1.containsKey('quellen')) {
          buffer.writeln('### Offizielle Quellen');
          for (var quelle in view1['quellen'] as List) {
            buffer.writeln('- $quelle');
          }
          buffer.writeln();
        }
      }
      
      if (structured.containsKey('sichtweise2_alternativ')) {
        final view2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;
        if (view2 != null && view2.containsKey('quellen')) {
          buffer.writeln('### Alternative Quellen');
          for (var quelle in view2['quellen'] as List) {
            buffer.writeln('- $quelle');
          }
          buffer.writeln();
        }
      }
    }
    
    buffer.writeln('---');
    buffer.writeln();
    
    // ANALYSE
    buffer.writeln('## 📊 ANALYSE (Mainstream-Narrativ)');
    buffer.writeln();
    if (structured != null && structured.containsKey('sichtweise1_offiziell')) {
      final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
      if (view1 != null && view1.containsKey('interpretation')) {
        buffer.writeln(view1['interpretation']);
        buffer.writeln();
      }
    }
    
    buffer.writeln('---');
    buffer.writeln();
    
    // ALTERNATIVE SICHT
    buffer.writeln('## 👁️ ALTERNATIVE SICHT');
    buffer.writeln();
    if (structured != null && structured.containsKey('sichtweise2_alternativ')) {
      final view2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;
      if (view2 != null && view2.containsKey('interpretation')) {
        buffer.writeln(view2['interpretation']);
        buffer.writeln();
      }
    }
    
    buffer.writeln('---');
    buffer.writeln();
    
    // Vollständiger Inhalt als Fallback
    if (inhalt.isNotEmpty) {
      buffer.writeln('## 📄 VOLLSTÄNDIGE ANALYSE');
      buffer.writeln();
      buffer.writeln(inhalt);
    }
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Generiert von WELTENBIBLIOTHEK v5.6*');
    
    _downloadFile(buffer.toString(), '$filename.md', 'text/markdown');
  }

  /// JSON-EXPORT
  static void _downloadJSON(Map<String, dynamic> data, String query, String filename) {
    // JSON mit Metadaten
    final exportData = {
      'meta': {
        'query': query,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 'WELTENBIBLIOTHEK v5.6',
      },
      'data': data,
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    _downloadFile(jsonString, '$filename.json', 'application/json');
  }

  /// TEXT-EXPORT
  static void _generateText(Map<String, dynamic> data, String query, String filename) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 60);
    buffer.writeln('WELTENBIBLIOTHEK RECHERCHE');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln('Thema: $query');
    buffer.writeln('Datum: ${DateTime.now().toLocal()}');
    buffer.writeln();
    buffer.writeln('=' * 60);
    buffer.writeln();
    
    // Inhalt
    final inhalt = data['inhalt'] as String? ?? '';
    if (inhalt.isNotEmpty) {
      buffer.writeln(inhalt);
    } else {
      buffer.writeln('Keine Analyse verfügbar.');
    }
    
    buffer.writeln();
    buffer.writeln('=' * 60);
    buffer.writeln('Generiert von WELTENBIBLIOTHEK v5.6');
    buffer.writeln('=' * 60);
    
    _downloadFile(buffer.toString(), '$filename.txt', 'text/plain');
  }

  /// HELPER: File-Download (Web)
  static void _downloadFile(String content, String filename, String mimeType) {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      throw Exception('File-Download nur für Web verfügbar');
    }
  }

  /// HELPER: HTML-Dokument für PDF generieren
  static String _buildHTMLDocument(Map<String, dynamic> data, String query) {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="de">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <title>WELTENBIBLIOTHEK - $query</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; line-height: 1.6; margin: 40px; }');
    buffer.writeln('    h1 { color: #1976D2; border-bottom: 3px solid #1976D2; padding-bottom: 10px; }');
    buffer.writeln('    h2 { color: #0D47A1; margin-top: 30px; border-left: 5px solid #2196F3; padding-left: 10px; }');
    buffer.writeln('    h3 { color: #424242; }');
    buffer.writeln('    .meta { background: #E3F2FD; padding: 15px; border-radius: 5px; margin-bottom: 30px; }');
    buffer.writeln('    .section { margin-bottom: 30px; page-break-inside: avoid; }');
    buffer.writeln('    .facts { background: #E8F5E9; padding: 15px; border-left: 5px solid #4CAF50; }');
    buffer.writeln('    .sources { background: #FFF3E0; padding: 15px; border-left: 5px solid #FF9800; }');
    buffer.writeln('    .analysis { background: #FCE4EC; padding: 15px; border-left: 5px solid #E91E63; }');
    buffer.writeln('    ul { margin: 10px 0; padding-left: 30px; }');
    buffer.writeln('    li { margin: 5px 0; }');
    buffer.writeln('    .footer { margin-top: 50px; text-align: center; color: #757575; border-top: 1px solid #BDBDBD; padding-top: 20px; }');
    buffer.writeln('    @media print { body { margin: 20px; } }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    
    // Header
    buffer.writeln('  <h1>WELTENBIBLIOTHEK RECHERCHE</h1>');
    buffer.writeln('  <div class="meta">');
    buffer.writeln('    <strong>Thema:</strong> $query<br>');
    buffer.writeln('    <strong>Datum:</strong> ${DateTime.now().toLocal()}<br>');
    buffer.writeln('    <strong>Version:</strong> WELTENBIBLIOTHEK v5.6');
    buffer.writeln('  </div>');
    
    final structured = data['structured'] as Map<String, dynamic>?;
    
    // FAKTEN
    if (structured != null && structured.containsKey('faktenbasis')) {
      buffer.writeln('  <div class="section facts">');
      buffer.writeln('    <h2>📌 FAKTEN</h2>');
      
      final fb = structured['faktenbasis'] as Map<String, dynamic>;
      
      if (fb.containsKey('facts') && fb['facts'] is List && (fb['facts'] as List).isNotEmpty) {
        buffer.writeln('    <h3>Belegbare Fakten</h3>');
        buffer.writeln('    <ul>');
        for (var fact in fb['facts']) {
          buffer.writeln('      <li>${_escapeHtml(fact.toString())}</li>');
        }
        buffer.writeln('    </ul>');
      }
      
      if (fb.containsKey('actors') && fb['actors'] is List && (fb['actors'] as List).isNotEmpty) {
        buffer.writeln('    <h3>Beteiligte Akteure</h3>');
        buffer.writeln('    <ul>');
        for (var actor in fb['actors']) {
          buffer.writeln('      <li>${_escapeHtml(actor.toString())}</li>');
        }
        buffer.writeln('    </ul>');
      }
      
      buffer.writeln('  </div>');
    }
    
    // QUELLEN
    if (structured != null) {
      buffer.writeln('  <div class="section sources">');
      buffer.writeln('    <h2>🔗 QUELLEN</h2>');
      
      if (structured.containsKey('sichtweise1_offiziell')) {
        final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
        if (view1 != null && view1.containsKey('quellen')) {
          buffer.writeln('    <h3>Offizielle Quellen</h3>');
          buffer.writeln('    <ul>');
          for (var quelle in view1['quellen'] as List) {
            buffer.writeln('      <li>${_escapeHtml(quelle.toString())}</li>');
          }
          buffer.writeln('    </ul>');
        }
      }
      
      buffer.writeln('  </div>');
    }
    
    // ANALYSE
    final inhalt = data['inhalt'] as String? ?? '';
    if (inhalt.isNotEmpty) {
      buffer.writeln('  <div class="section analysis">');
      buffer.writeln('    <h2>📄 ANALYSE</h2>');
      buffer.writeln('    <p>${_escapeHtml(inhalt).replaceAll('\n', '<br>')}</p>');
      buffer.writeln('  </div>');
    }
    
    // Footer
    buffer.writeln('  <div class="footer">');
    buffer.writeln('    <p>Generiert von <strong>WELTENBIBLIOTHEK v5.6</strong></p>');
    buffer.writeln('  </div>');
    
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    return buffer.toString();
  }

  /// HELPER: HTML-Escape
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Export-Dialog anzeigen
  static void showExportDialog(
    BuildContext context, {
    required Map<String, dynamic> data,
    required String query,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Export'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Wähle ein Export-Format:'),
            const SizedBox(height: 16),
            
            // PDF
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF-Dokument'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                exportResearch(
                  context: context,
                  data: data,
                  query: query,
                  format: 'pdf',
                );
              },
            ),
            const SizedBox(height: 8),
            
            // Markdown
            ElevatedButton.icon(
              icon: const Icon(Icons.text_fields),
              label: const Text('Markdown (.md)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                exportResearch(
                  context: context,
                  data: data,
                  query: query,
                  format: 'md',
                );
              },
            ),
            const SizedBox(height: 8),
            
            // JSON
            ElevatedButton.icon(
              icon: const Icon(Icons.code),
              label: const Text('JSON-Daten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                exportResearch(
                  context: context,
                  data: data,
                  query: query,
                  format: 'json',
                );
              },
            ),
            const SizedBox(height: 8),
            
            // TXT
            ElevatedButton.icon(
              icon: const Icon(Icons.description),
              label: const Text('Text-Datei (.txt)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                exportResearch(
                  context: context,
                  data: data,
                  query: query,
                  format: 'txt',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }
}
