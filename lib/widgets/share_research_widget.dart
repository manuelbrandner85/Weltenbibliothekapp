import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'qr_code_share_dialog.dart';
import 'social_media_share_widget.dart';

/// Share Research Widget v7.5
/// 
/// Teilen-Funktion für Recherche-Ergebnisse
class ShareResearchWidget extends StatelessWidget {
  final String query;
  final String summary;
  final List<dynamic>? sources;
  final Map<String, dynamic>? multimedia;

  const ShareResearchWidget({
    super.key,
    required this.query,
    required this.summary,
    this.sources,
    this.multimedia,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share, color: Colors.cyan),
      onPressed: () => _showShareOptions(context),
      tooltip: 'Recherche teilen',
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recherche teilen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Share Options
            _buildShareOption(
              context,
              icon: Icons.text_fields,
              title: 'Als Text teilen',
              description: 'Kopiere oder teile den Text',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _shareAsText();
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.picture_as_pdf,
              title: 'Als PDF exportieren',
              description: 'Erstelle ein PDF-Dokument',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _shareAsPdf(context);
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.link,
              title: 'Link kopieren',
              description: 'Kopiere Deep-Link zur Recherche',
              color: Colors.cyan,
              onTap: () {
                Navigator.pop(context);
                _copyLink(context);
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.qr_code,
              title: 'QR-Code anzeigen',
              description: 'Teile per QR-Code',
              color: Colors.cyan,
              onTap: () {
                Navigator.pop(context);
                _showQrCode(context);
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.share_outlined,
              title: 'Social Media',
              description: 'Auf Twitter, Reddit, Telegram teilen',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                _showSocialMediaShare(context);
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.code,
              title: 'Embed-Code',
              description: 'Code für Website-Einbindung',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _showEmbedCode(context);
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              context,
              icon: Icons.content_copy,
              title: 'Quellen kopieren',
              description: 'Kopiere alle Quellen-URLs',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _copySourcesOnly(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsText() async {
    final text = _buildShareText();
    await Share.share(
      text,
      subject: 'Weltenbibliothek Recherche: $query',
    );
  }

  Future<void> _shareAsPdf(BuildContext context) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('PDF wird erstellt...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final pdf = await _generatePdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/weltenbibliothek_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Weltenbibliothek Recherche: $query',
        text: 'Recherche-Ergebnis zu: $query',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 16),
                Text('PDF erfolgreich erstellt!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen des PDFs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    final link = 'weltenbibliothek://research?q=${Uri.encodeComponent(query)}';
    await Clipboard.setData(ClipboardData(text: link));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 16),
              Text('Link in Zwischenablage kopiert!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copySourcesOnly(BuildContext context) async {
    if (sources == null || sources!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Quellen verfügbar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final sourcesText = StringBuffer();
    sourcesText.writeln('📚 QUELLEN für: $query\n');
    
    for (int i = 0; i < sources!.length; i++) {
      final source = sources![i];
      sourcesText.writeln('${i + 1}. ${source['title'] ?? 'Unbekannt'}');
      sourcesText.writeln('   ${source['url'] ?? ''}');
      sourcesText.writeln('   Type: ${source['type'] ?? 'N/A'}\n');
    }

    await Clipboard.setData(ClipboardData(text: sourcesText.toString()));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 16),
              Text('${sources!.length} Quellen kopiert!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 WELTENBIBLIOTHEK RECHERCHE');
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln('📌 Thema: $query');
    buffer.writeln();
    buffer.writeln('📝 ZUSAMMENFASSUNG:');
    buffer.writeln(summary);
    buffer.writeln();
    
    if (sources != null && sources!.isNotEmpty) {
      buffer.writeln('📚 QUELLEN (${sources!.length}):');
      for (int i = 0; i < sources!.length; i++) {
        final source = sources![i];
        buffer.writeln('${i + 1}. ${source['title'] ?? 'Unbekannt'}');
        buffer.writeln('   ${source['url'] ?? ''}');
      }
      buffer.writeln();
    }
    
    if (multimedia != null) {
      final docs = multimedia!['documents'] as List?;
      final images = multimedia!['images'] as List?;
      final videos = multimedia!['videos'] as List?;
      
      if (docs != null && docs.isNotEmpty) {
        buffer.writeln('📄 Dokumente: ${docs.length}');
      }
      if (images != null && images.isNotEmpty) {
        buffer.writeln('🖼️ Bilder: ${images.length}');
      }
      if (videos != null && videos.isNotEmpty) {
        buffer.writeln('🎥 Videos: ${videos.length}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('═' * 40);
    buffer.writeln('Erstellt mit Weltenbibliothek v7.5');
    buffer.writeln('Alternative Narrative & Verschwörungstheorien');
    
    return buffer.toString();
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              'WELTENBIBLIOTHEK RECHERCHE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Query
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.cyan, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'Thema: $query',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Summary
          pw.Header(level: 1, text: 'ZUSAMMENFASSUNG'),
          pw.SizedBox(height: 10),
          pw.Text(summary, textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 20),
          
          // Sources
          if (sources != null && sources!.isNotEmpty) ...[
            pw.Header(level: 1, text: 'QUELLEN (${sources!.length})'),
            pw.SizedBox(height: 10),
            ...sources!.asMap().entries.map((entry) {
              final source = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${entry.key + 1}. ${source['title'] ?? 'Unbekannt'}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${source['url'] ?? 'Keine URL'}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue),
                    ),
                    if (source['type'] != null)
                      pw.Text(
                        'Typ: ${source['type']}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                      ),
                  ],
                ),
              );
            }),
          ],
          
          // Footer
          pw.SizedBox(height: 40),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Erstellt mit Weltenbibliothek v7.5 - ${DateTime.now().toString().split('.')[0]}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
    
    return pdf;
  }
  
  // 🆕 QR-Code anzeigen
  void _showQrCode(BuildContext context) {
    final url = 'https://weltenbibliothek.app/recherche?q=${Uri.encodeComponent(query)}';
    
    showDialog(
      context: context,
      builder: (context) => QrCodeShareDialog(
        url: url,
        title: 'Recherche: $query',
      ),
    );
  }
  
  // 🆕 Social Media Share
  void _showSocialMediaShare(BuildContext context) {
    final url = 'https://weltenbibliothek.app/recherche?q=${Uri.encodeComponent(query)}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Social Media Widget
            SocialMediaShareWidget(
              query: query,
              url: url,
            ),
          ],
        ),
      ),
    );
  }
  
  // 🆕 Embed-Code anzeigen
  void _showEmbedCode(BuildContext context) {
    final url = 'https://weltenbibliothek.app/recherche?q=${Uri.encodeComponent(query)}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Embed Code Widget
            EmbedCodeWidget(
              url: url,
              title: 'Recherche: $query',
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
